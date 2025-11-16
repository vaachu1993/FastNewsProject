// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);


  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      print('🔵 [CheckEmail] Starting check for: $email');

      // ✅ BƯỚC 1: Kiểm tra trong Firestore (nguồn tin cậy nhất)
      try {
        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));

        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          final providers = List<String>.from(userData['providers'] ?? []);

          print('🟢 [CheckEmail] Email exists in Firestore');
          print('🔵 [CheckEmail] Providers: $providers');

          // Trả về provider đầu tiên (vì single-provider policy)
          final provider = providers.isNotEmpty ? providers.first : null;
          return {
            'exists': true,
            'provider': provider,
          };
        }

        print('🟢 [CheckEmail] Email NOT found in Firestore');
      } catch (e) {
        print('🟡 [CheckEmail] Firestore check failed: $e');
        // Continue to Firebase Auth check
      }

      // ✅ BƯỚC 2: Fallback - Kiểm tra trong Firebase Auth
      try {
        // ignore: deprecated_member_use
        final methods = await _auth
            .fetchSignInMethodsForEmail(email.trim())
            .timeout(const Duration(seconds: 5));

        if (methods.isNotEmpty) {
          print('🟢 [CheckEmail] Email exists in Firebase Auth');
          print('🔵 [CheckEmail] Methods: $methods');

          // Determine provider from methods
          String? provider;
          if (methods.contains('password')) {
            provider = 'password';
          } else if (methods.contains('google.com')) {
            provider = 'google.com';
          }

          return {
            'exists': true,
            'provider': provider,
          };
        }

        print('🟢 [CheckEmail] Email NOT found in Firebase Auth');
      } catch (e) {
        print('🟡 [CheckEmail] Firebase Auth check failed: $e');
      }

      // ✅ Email không tồn tại
      print('🟢 [CheckEmail] Email is available for registration');
      return {
        'exists': false,
        'provider': null,
      };

    } catch (e) {
      print('🔴 [CheckEmail] Unexpected error: $e');
      return {
        'exists': false,
        'provider': null,
      };
    }
  }

  // ============================================
  // 1. SIGN UP WITH EMAIL AND PASSWORD
  // ============================================
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('🔵 Creating email/password account for: $email');

      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'displayName': name,
        'email': email,
        'photoURL': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'loginMethod': 'email',
        'providers': ['password'], // ✅ Only password provider initially
        'emailVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verificationMethod': 'otp',
        'bookmarks': [],
      });

      print('🟢 Email/password account created successfully');
      return null; // Success

    } on FirebaseAuthException catch (e) {
      print('🔴 Sign up error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng dùng mật khẩu mạnh hơn.';
        case 'email-already-in-use':
          return 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        default:
          return 'Đã xảy ra lỗi: ${e.message}';
      }
    } catch (e) {
      print('🔴 Sign up exception: $e');
      return 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  // ============================================
  // 2. SIGN IN WITH EMAIL AND PASSWORD
  // ============================================
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Signing in with email: $email');

      // ✅ STEP 1A: Check Firebase Auth methods
      List<String> existingMethods = [];
      try {
        // ignore: deprecated_member_use
        existingMethods = await _auth.fetchSignInMethodsForEmail(email).timeout(
          const Duration(seconds: 3),
          onTimeout: () => [],
        );
        print('🔵 Existing methods for $email: $existingMethods');
      } catch (e) {
        print('🟡 Could not fetch sign-in methods: $e');
      }

      // ✅ STEP 1B: CRITICAL - Also check Firestore for existing user
      print('🔵 Checking Firestore for existing user with email: $email');

      try {
        final existingUserQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingUserQuery.docs.isNotEmpty) {
          final existingUserDoc = existingUserQuery.docs.first;
          final userData = existingUserDoc.data();
          final providers = List<String>.from(userData['providers'] ?? []);

          print('🔵 Found existing user in Firestore with providers: $providers');

          // ✅ STEP 2A: Block if user exists with Google provider only
          if (providers.contains('google.com') && !providers.contains('password')) {
            print('🔴 User exists with Google provider - BLOCKING password login');
            return '❌ Email này đã được đăng ký bằng Google. Vui lòng đăng nhập bằng Google thay vì email/mật khẩu.';
          }
        }
      } catch (e) {
        print('🟡 Layer 1 (Firestore check) failed: $e');
        print('🟡 Falling back to Layer 2 (Firebase Auth check)');
        // Continue to Layer 2 - not a critical error
      }

      // ✅ STEP 2B: Double check with Firebase Auth methods
      if (existingMethods.contains('google.com') && !existingMethods.contains('password')) {
        print('🔴 Email registered with Google in Firebase Auth - password login blocked');
        return '❌ Email này đã được đăng ký bằng Google. Vui lòng đăng nhập bằng Google thay vì email/mật khẩu.';
      }

      // ✅ STEP 3: Attempt password login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ STEP 4: Enforce single provider in Firestore
      if (userCredential.user != null) {
        await _ensureSingleProvider(userCredential.user!.uid, 'password');

        // Update last login time (non-blocking)
        _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'loginMethod': 'email',
        }).catchError((e) {
          print('🟡 Warning: Could not update lastLoginAt: $e');
        });
      }

      print('🟢 Email/password sign in successful');
      return null; // Success

    } on FirebaseAuthException catch (e) {
      print('🔴 Sign in error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'wrong-password':
          return 'Mật khẩu không chính xác.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        case 'user-disabled':
          return 'Tài khoản này đã bị vô hiệu hóa.';
        case 'invalid-credential':
          return 'Thông tin đăng nhập không chính xác. Email này có thể đã được đăng ký bằng Google.';
        default:
          return 'Đã xảy ra lỗi: ${e.message}';
      }
    } catch (e) {
      print('🔴 Sign in exception: $e');
      return 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  // ============================================
  // 3. SIGN IN WITH GOOGLE (Single Provider Policy)
  // ============================================
  /// Flow đăng nhập Google với chính sách single-provider:
  /// 1. Trigger Google sign-in flow
  /// 2. Kiểm tra email đã tồn tại với provider nào
  /// 3. Nếu tồn tại với password → CHẶN, yêu cầu dùng password
  /// 4. Nếu email mới hoặc đã có google → Sign in bình thường
  /// 5. Cập nhật Firestore với ONLY google.com provider
  Future<String?> signInWithGoogle() async {
    GoogleSignInAccount? googleUser;

    try {
      print('🔵 Starting Google Sign In...');

      // ✅ STEP 1: Trigger Google authentication flow
      googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('🔴 User cancelled Google Sign In');
        return 'Đăng nhập bị hủy';
      }

      final email = googleUser.email;
      print('🔵 Google user email: $email');
      print('🔵 Email type: ${email.runtimeType}');
      print('🔵 Email length: ${email.length}');
      print('🔵 Email trimmed: "${email.trim()}"');

      // ✅ STEP 2A: Check Firebase Auth for existing methods
      List<String> existingMethods = [];
      try {
        // ignore: deprecated_member_use
        existingMethods = await _auth
            .fetchSignInMethodsForEmail(email)
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                print('⚡ fetchSignInMethodsForEmail timeout - continuing');
                return [];
              },
            );
        print('🔵 Existing sign-in methods for $email: $existingMethods');
      } catch (e) {
        print('🟡 Could not fetch sign-in methods (might be new user): $e');
      }

      // ✅ STEP 2B: CRITICAL - Check Firestore for existing user with THIS EMAIL
      print('🔵 ========================================');
      print('🔵 CHECKING FIRESTORE FOR EXISTING USER');
      print('🔵 ========================================');
      print('🔵 Email being checked: "$email"');
      print('🔵 Query: collection("users").where("email", isEqualTo: "$email")');

      bool emailAlreadyExists = false;
      bool hasPasswordProvider = false;
      bool hasGoogleProvider = false; // ✅ NEW: Track if user has Google provider
      String? existingProvider;

      try {
        print('🔵 Executing Firestore query...');
        final existingUserQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        print('🔵 ========================================');
        print('🔵 FIRESTORE QUERY RESULT');
        print('🔵 ========================================');
        print('🔵 Documents returned: ${existingUserQuery.docs.length}');

        if (existingUserQuery.docs.isNotEmpty) {
          emailAlreadyExists = true;
          final existingUserDoc = existingUserQuery.docs.first;
          final userData = existingUserDoc.data();
          final providers = List<String>.from(userData['providers'] ?? []);
          final existingEmail = userData['email'] as String?;

          print('🔵 Found existing user in Firestore:');
          print('   - Email: $existingEmail');
          print('   - Providers: $providers');
          print('   - UID: ${existingUserDoc.id}');

          if (providers.isNotEmpty) {
            existingProvider = providers[0];
          }

          if (providers.contains('password')) {
            hasPasswordProvider = true;
            print('🔴 DETECTED: User has password provider in Firestore');
          }

          if (providers.contains('google.com')) {
            hasGoogleProvider = true;
            print('🟢 DETECTED: User has google.com provider - allowing re-login');
          }
        } else {
          print('🟡 Query where() returned 0 documents');
          print('🟡 Trying alternative check: Get all users and filter manually...');

          // Alternative check: Get all users and filter
          try {
            final allUsers = await _firestore.collection('users').get();
            print('🔵 Total users in database: ${allUsers.docs.length}');

            for (var doc in allUsers.docs) {
              final data = doc.data();
              final docEmail = data['email'] as String?;

              if (docEmail != null) {
                final docEmailTrimmed = docEmail.trim().toLowerCase();
                final searchEmailTrimmed = email.trim().toLowerCase();

                print('🔵 Comparing: "$docEmailTrimmed" == "$searchEmailTrimmed"');

                if (docEmailTrimmed == searchEmailTrimmed) {
                  print('🔴 FOUND MATCH! User exists with this email');
                  emailAlreadyExists = true;

                  final providers = List<String>.from(data['providers'] ?? []);
                  print('🔵 User providers: $providers');

                  if (providers.contains('password')) {
                    hasPasswordProvider = true;
                    existingProvider = 'Email/Password';
                    print('🔴 DETECTED: User has password provider (manual check)');
                  }

                  if (providers.contains('google.com')) {
                    hasGoogleProvider = true;
                    print('🟢 DETECTED: User has google.com provider (manual check)');
                  }
                  break;
                }
              }
            }

            if (!emailAlreadyExists) {
              print('🟢 No existing user found in Firestore with this email (manual check)');
            }
          } catch (manualCheckError) {
            print('🔴 Manual check also failed: $manualCheckError');
          }
        }
      } catch (e) {
        print('🟡 Layer 1 (Firestore check) failed: $e');
        print('🟡 Falling back to Layer 2 (Firebase Auth check)');
      }

      // ✅ STEP 2C: Also check Firebase Auth methods
      if (existingMethods.isNotEmpty && !existingMethods.contains('google.com')) {
        print('🔴 DETECTED: Email exists in Firebase Auth with methods: $existingMethods');
        emailAlreadyExists = true;

        if (existingMethods.contains('password')) {
          hasPasswordProvider = true;
          existingProvider = 'Email/Password';
          print('🔴 DETECTED: User has password provider in Firebase Auth');
        }
      }

      // ✅ STEP 3: BLOCK ONLY if email has PASSWORD provider
      print('🔵 ========================================');
      print('🔵 DECISION MAKING');
      print('🔵 ========================================');
      print('🔵 emailAlreadyExists: $emailAlreadyExists');
      print('🔵 hasPasswordProvider: $hasPasswordProvider');
      print('🔵 hasGoogleProvider: $hasGoogleProvider');
      print('🔵 existingProvider: $existingProvider');

      // ⚡ NEW LOGIC: Only block if password provider exists, allow Google re-login
      if (hasPasswordProvider) {
        print('🔴 ========================================');
        print('🔴 BLOCKING GOOGLE LOGIN');
        print('🔴 ========================================');
        print('🔴 Reason: EMAIL ALREADY IN USE WITH PASSWORD PROVIDER');
        print('🔴 Email: $email');
        print('🔴 Existing provider: $existingProvider');
        print('🔴 Action: Preventing duplicate account creation');
        print('🔴 Cleaning up Google session...');
        await _googleSignIn.signOut();
        print('🔴 Google sign out completed');
        print('🔴 Returning error message to user');
        return '❌ Email này đã được đăng ký bằng Email/Mật khẩu. Vui lòng đăng nhập bằng email/mật khẩu.';
      }

      if (hasGoogleProvider) {
        print('🟢 ========================================');
        print('🟢 GOOGLE RE-LOGIN DETECTED');
        print('🟢 ========================================');
        print('🟢 User is logging back in with same Google account');
        print('🟢 Allowing sign-in...');
      } else {
        print('🟢 ========================================');
        print('🟢 NEW GOOGLE ACCOUNT');
        print('🟢 ========================================');
        print('🟢 Creating new account with Google provider');
      }

      // ✅ STEP 4: Get Google authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('🔵 Got Google authentication tokens');

      // ✅ STEP 5: Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('🔵 Created Firebase credential');


      // ✅ STEP 6: Sign in to Firebase with Google credential
      print('🔵 ========================================');
      print('🔵 CALLING signInWithCredential()');
      print('🔵 ========================================');

      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);

        print('🟢 ========================================');
        print('🟢 FIREBASE AUTH SIGN IN SUCCESSFUL');
        print('🟢 ========================================');
        print('🟢 Email: ${userCredential.user?.email}');
        print('🟢 UID: ${userCredential.user?.uid}');
        print('🟢 Display Name: ${userCredential.user?.displayName}');
        print('🟢 Creation Time: ${userCredential.user?.metadata.creationTime}');
        print('🟢 Last Sign In: ${userCredential.user?.metadata.lastSignInTime}');

        // 🚨 CRITICAL POST-SIGN-IN CHECK: Only block if password provider exists
        if (hasPasswordProvider && !hasGoogleProvider) {
          print('🔴🔴🔴 CRITICAL VIOLATION DETECTED 🔴🔴🔴');
          print('🔴 Email "$email" already exists with PASSWORD provider!');
          print('🔴 This violates single-email policy');
          print('🔴 Checking if this is a NEW account or existing account...');

          // Check if this is actually a new account created
          final signedInUser = userCredential.user;
          if (signedInUser != null) {
            final metadata = signedInUser.metadata;
            final isNewAccount = metadata.creationTime != null &&
                                metadata.lastSignInTime != null &&
                                metadata.creationTime!.difference(metadata.lastSignInTime!).inSeconds.abs() < 5;

            if (isNewAccount) {
              print('🔴 DETECTED: This is a NEWLY CREATED account (creation time ≈ sign-in time)');
              print('🔴 DELETING this duplicate account immediately...');

              try {
                await signedInUser.delete();
                print('🟢 Successfully deleted duplicate Google account');
              } catch (deleteError) {
                print('🔴 Failed to delete account: $deleteError');
              }

              await _auth.signOut();
              await _googleSignIn.signOut();

              return '❌ Email này đã được đăng ký bằng Email/Mật khẩu. Vui lòng đăng nhập bằng email/mật khẩu.';
            } else {
              print('🟡 This appears to be an existing Google account, allowing sign in');
            }
          }
        } else if (hasGoogleProvider) {
          print('🟢 Google account re-login successful');
        }

      } on FirebaseAuthException catch (e) {
        // Handle account exists with different credential
        if (e.code == 'account-exists-with-different-credential') {
          print('🔴 Account exists with different credential');
          await _googleSignIn.signOut();
          return '❌ Email này đã được đăng ký bằng phương thức khác. Vui lòng sử dụng phương thức đăng nhập ban đầu.';
        }
        rethrow; // Re-throw other Firebase auth errors
      }

      // ✅ STEP 7: Create or update user document - enforce single provider
      try {
        await _createOrUpdateGoogleUserDocument(
          userCredential: userCredential,
          email: email,
          photoURL: googleUser.photoUrl,
        );
      } catch (e) {
        // Safety check failed - user has password provider
        print('🔴 Safety check exception: $e');
        await _googleSignIn.signOut();
        return '❌ Email này đã được đăng ký bằng Email/Mật khẩu. Vui lòng đăng nhập bằng email/mật khẩu thay vì Google.';
      }

      return null; // Success

    } on FirebaseAuthException catch (e) {
      print('🔴 FirebaseAuthException: ${e.code} - ${e.message}');

      // Handle account exists with different credential (safety net)
      if (e.code == 'account-exists-with-different-credential') {
        await _googleSignIn.signOut();
        return '❌ Email này đã được đăng ký bằng phương thức khác. Vui lòng sử dụng phương thức đăng nhập ban đầu.';
      }

      await _googleSignIn.signOut(); // Clean up Google session

      switch (e.code) {
        case 'invalid-credential':
          return 'Thông tin xác thực Google không hợp lệ.';
        case 'operation-not-allowed':
          return 'Đăng nhập Google chưa được kích hoạt. Vui lòng liên hệ quản trị viên.';
        case 'user-disabled':
          return 'Tài khoản này đã bị vô hiệu hóa.';
        default:
          return 'Lỗi đăng nhập Google: ${e.message}';
      }
    } catch (e) {
      print('🔴 Google Sign In exception: $e');
      await _googleSignIn.signOut(); // Clean up
      return 'Đã xảy ra lỗi: $e';
    }
  }

  // ============================================
  // 4. ENSURE SINGLE PROVIDER (Helper Method)
  // ============================================
  /// Đảm bảo tài khoản chỉ có DUY NHẤT 1 provider trong Firestore
  /// Xóa tất cả providers khác, chỉ giữ lại provider hiện tại
  ///
  /// Parameters:
  /// - uid: User ID
  /// - correctProvider: Provider duy nhất được giữ lại ('password' hoặc 'google.com')
  Future<void> _ensureSingleProvider(String uid, String correctProvider) async {
    try {
      print('🔵 Ensuring single provider for UID: $uid - Provider: $correctProvider');

      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        List<String> currentProviders = List<String>.from(userData['providers'] ?? []);

        print('🔵 Current providers: $currentProviders');

        // Nếu đã đúng 1 provider và đúng loại → không cần update
        if (currentProviders.length == 1 && currentProviders[0] == correctProvider) {
          print('✅ Already single provider: $correctProvider');
          return;
        }

        // ✅ CRITICAL: Cập nhật lại chỉ còn 1 provider duy nhất
        await _firestore.collection('users').doc(uid).update({
          'providers': [correctProvider], // Chỉ 1 provider
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('🟢 Updated to single provider: [$correctProvider]');
      } else {
        print('🟡 User document does not exist - will be created on first login');
      }
    } catch (e) {
      print('🔴 Error ensuring single provider: $e');
    }
  }

  // ============================================
  // HELPER: CREATE OR UPDATE GOOGLE USER DOCUMENT
  // ============================================
  Future<void> _createOrUpdateGoogleUserDocument({
    required UserCredential userCredential,
    required String email,
    String? photoURL,
  }) async {
    final uid = userCredential.user?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      // New Google user - create document
      print('🟢 Creating new Google user document');
      await _firestore.collection('users').doc(uid).set({
        'displayName': userCredential.user?.displayName ?? 'Google User',
        'email': email,
        'photoURL': photoURL ?? userCredential.user?.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'loginMethod': 'google',
        'providers': ['google.com'], // ✅ Only Google - single provider
        'emailVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verificationMethod': 'google',
        'bookmarks': [],
      });
      print('🟢 Google user document created with single provider');

    } else {
      // ✅ Existing user - CHECK before updating
      print('🟢 Updating existing user - checking existing provider');

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentProviders = List<String>.from(userData['providers'] ?? []);

      print('🔵 Current providers in Firestore: $currentProviders');

      // 🚨 CRITICAL SAFETY CHECK: DO NOT overwrite password provider
      if (currentProviders.contains('password')) {
        print('🔴🔴🔴 SAFETY CHECK FAILED: User has password provider 🔴🔴🔴');
        print('🔴 This should have been blocked earlier!');
        print('🔴 Firebase may have merged accounts - ROLLING BACK...');

        // 🔧 ROLLBACK STRATEGY: Unlink Google provider if it was added
        try {
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            final providerData = currentUser.providerData;
            print('🔵 Current Firebase Auth providers: ${providerData.map((p) => p.providerId).toList()}');

            // Check if Google provider was added to this account
            if (providerData.any((p) => p.providerId == 'google.com')) {
              print('🔴 Detected Google provider in Firebase Auth - Unlinking...');

              try {
                await currentUser.unlink('google.com');
                print('🟢 Successfully unlinked Google provider');
              } catch (unlinkError) {
                print('🔴 Failed to unlink Google: $unlinkError');
                // If unlink fails, force delete and sign out
              }
            }
          }
        } catch (rollbackError) {
          print('🔴 Rollback error: $rollbackError');
        }

        // Force sign out both Firebase and Google
        print('🔴 Forcing sign out...');
        await _auth.signOut();
        await _googleSignIn.signOut();
        print('🔴 Sign out completed');

        throw Exception('Security violation: Attempted to overwrite password provider with Google');
      }

      // Only proceed if user already has google.com or no providers
      if (currentProviders.isEmpty || currentProviders.contains('google.com')) {
        print('🟢 Safe to update - enforcing Google provider');

        await _firestore.collection('users').doc(uid).update({
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'providers': ['google.com'], // ✅ OVERRIDE to single provider
          'loginMethod': 'google',
          'photoURL': photoURL ?? userCredential.user?.photoURL ?? '',
        });

        print('🟢 User providers enforced to single provider: [google.com]');
      } else {
        print('🔴 Unknown provider state: $currentProviders - Aborting');
        await _auth.signOut();
        await _googleSignIn.signOut();
        throw Exception('Unknown provider state');
      }
    }
  }

  // ============================================
  // SIGN OUT
  // ============================================
  Future<void> signOut() async {
    print('🔵 Signing out...');
    await _googleSignIn.signOut();
    await _auth.signOut();
    print('🟢 Signed out successfully');
  }

  // ============================================
  // RESET PASSWORD
  // ============================================
  Future<String?> resetPassword(String email) async {
    try {
      print('🔵 Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('🟢 Password reset email sent');
      return null; // Success

    } on FirebaseAuthException catch (e) {
      print('🔴 Reset password error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        default:
          return 'Đã xảy ra lỗi: ${e.message}';
      }
    } catch (e) {
      print('🔴 Reset password exception: $e');
      return 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  // ============================================
  // GET USER DATA
  // ============================================
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('🔴 Error getting user data: $e');
      return null;
    }
  }

  // ============================================
  // CHECK EMAIL VERIFICATION STATUS
  // ============================================
  Future<bool> isEmailVerified(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?['emailVerified'] ?? false;
    } catch (e) {
      print('🔴 Error checking email verification: $e');
      return false;
    }
  }

  // ============================================
  // GET VERIFICATION INFO
  // ============================================
  Future<Map<String, dynamic>?> getVerificationInfo(String uid) async {
    try {
      final userData = await getUserData(uid);
      if (userData != null && userData['emailVerified'] == true) {
        return {
          'isVerified': true,
          'verifiedAt': userData['verifiedAt'],
          'verificationMethod': userData['verificationMethod'] ?? 'unknown',
        };
      }
      return {'isVerified': false};
    } catch (e) {
      print('🔴 Error getting verification info: $e');
      return null;
    }
  }

  // ============================================
  // UPDATE USER PROFILE
  // ============================================
  Future<void> updateUserProfile({String? name, String? photoUrl}) async {
    User? user = currentUser;
    if (user != null) {
      if (name != null) {
        await user.updateDisplayName(name);
        await _firestore.collection('users').doc(user.uid).update({
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
        await _firestore.collection('users').doc(user.uid).update({
          'photoURL': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}

