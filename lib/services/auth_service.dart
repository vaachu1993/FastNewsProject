// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'notification_service.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Add Web Client ID from google-services.json to fix DEVELOPER_ERROR
    serverClientId: '346373834818-bovjratu2qu8135ms6enn9ufh2he9jee.apps.googleusercontent.com',
  );


  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize authentication persistence
  Future<void> initializeAuth() async {
    try {
      // Note: Firebase Auth on Android automatically has persistence enabled
      // setPersistence() is only for web platforms
      print('🔵 Firebase Auth persistence is automatically enabled on Android');

      // Check if user is already signed in
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('🟢 User already signed in: ${currentUser.email}');
        await _saveLoginState(true, currentUser.uid);

        // Initialize notification service for signed-in user
        await _initializeNotificationsForUser();
      } else {
        print('🟡 No user currently signed in');
        await _saveLoginState(false, null);
      }
    } catch (e) {
      print('🔴 Error initializing auth persistence: $e');
    }
  }

  // Save login state to SharedPreferences
  Future<void> _saveLoginState(bool isLoggedIn, String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', isLoggedIn);
      if (userId != null) {
        await prefs.setString('user_id', userId);
      } else {
        await prefs.remove('user_id');
      }
      print('🔵 Login state saved: $isLoggedIn');
    } catch (e) {
      print('🔴 Error saving login state: $e');
    }
  }

  // Get login state from SharedPreferences
  Future<Map<String, dynamic>> getLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userId = prefs.getString('user_id');
      final currentUser = _auth.currentUser;

      // Verify consistency between SharedPreferences and Firebase Auth
      final isActuallyLoggedIn = currentUser != null && isLoggedIn;

      return {
        'isLoggedIn': isActuallyLoggedIn,
        'userId': currentUser?.uid ?? userId,
        'user': currentUser,
      };
    } catch (e) {
      print('🔴 Error getting login state: $e');
      return {
        'isLoggedIn': false,
        'userId': null,
        'user': null,
      };
    }
  }

  // Initialize notifications for signed-in user
  Future<void> _initializeNotificationsForUser() async {
    try {
      // Import NotificationService và start background checking
      final notificationService = NotificationService();
      final notificationsEnabled = await notificationService.areNotificationsEnabled();

      if (notificationsEnabled) {
        print('🔔 Starting notifications for signed-in user');
        await notificationService.startBackgroundNewsCheck();
      } else {
        print('🔕 Notifications disabled for user');
      }
    } catch (e) {
      print('🔴 Error initializing notifications: $e');
    }
  }

  // Check if user is currently authenticated
  Future<bool> isUserAuthenticated() async {
    final loginState = await getLoginState();
    return loginState['isLoggedIn'] as bool;
  }

  // Network connectivity check
  Future<bool> _hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('❌ Network check failed: $e');
      return false;
    }
  }

  // Enhanced error handler for auth operations
  Future<T?> _executeAuthOperation<T>(
    String operationName,
    Future<T> Function() operation,
    {T? fallbackValue}
  ) async {
    try {
      // Check network first
      final hasNetwork = await _hasNetworkConnection();
      if (!hasNetwork) {
        print('⚠️ No network connection for $operationName');
        throw const SocketException('No network connection');
      }

      return await operation();
    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Auth error in $operationName: ${e.code} - ${e.message}');
      rethrow; // Re-throw for specific handling
    } on FirebaseException catch (e) {
      print('🔥 Firebase error in $operationName: ${e.code} - ${e.message}');
      rethrow;
    } on SocketException catch (e) {
      print('🌐 Network error in $operationName: $e');
      rethrow;
    } catch (e) {
      print('❌ General error in $operationName: $e');
      rethrow;
    }
  }

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

      // ✅ Save login state after successful signup
      if (userCredential.user != null) {
        await _saveLoginState(true, userCredential.user!.uid);

        // ✅ Initialize notifications for new user
        await _initializeNotificationsForUser();
      }

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

        // ✅ Save login state
        await _saveLoginState(true, userCredential.user!.uid);

        // ✅ Initialize notifications for signed-in user
        await _initializeNotificationsForUser();

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
      // Check network first
      final hasNetwork = await _hasNetworkConnection();
      if (!hasNetwork) {
        print('⚠️ No network connection for Google Sign In');
        return '❌ Không có kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
      }

      print('🔵 Starting Google Sign In...');

      // ✅ STEP 1: Trigger Google authentication flow
      googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('🔴 User cancelled Google Sign In');
        return 'Đăng nhập bị hủy';
      }

      final email = googleUser.email;
      print('🔵 Google user email: $email');

      // ✅ STEP 2: Check for existing users with password provider
      try {
        final existingUserQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingUserQuery.docs.isNotEmpty) {
          final userData = existingUserQuery.docs.first.data();
          final providers = List<String>.from(userData['providers'] ?? []);

          // Block if user exists with password provider only
          if (providers.contains('password') && !providers.contains('google.com')) {
            print('🔴 User exists with password provider - BLOCKING Google login');
            await _googleSignIn.signOut();
            return '❌ Email này đã được đăng ký bằng Email/Mật khẩu.';
          }
        }
      } catch (e) {
        print('🟡 Firestore check failed: $e');
        // Continue with sign-in
      }

      // ✅ STEP 3: Get Google authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('🔵 Got Google authentication tokens');

      // ✅ STEP 4: Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('🔵 Created Firebase credential');

      // ✅ STEP 5: Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      print('🟢 Firebase Auth Sign In Successful');

      // ✅ STEP 6: Create or update user document
      await _createOrUpdateGoogleUserDocument(
        userCredential: userCredential,
        email: email,
        photoURL: googleUser.photoUrl,
      );

      // ✅ STEP 7: Save login state
      if (userCredential.user != null) {
        await _saveLoginState(true, userCredential.user!.uid);

        // ✅ Initialize notifications for signed-in user
        await _initializeNotificationsForUser();
      }

      return null; // Success

    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Auth error: ${e.code} - ${e.message}');

      if (googleUser != null) {
        await _googleSignIn.signOut();
      }

      switch (e.code) {
        case 'account-exists-with-different-credential':
          return '❌ Email này đã được đăng ký bằng phương thức khác.';
        case 'invalid-credential':
          return 'Thông tin xác thực Google không hợp lệ.';
        case 'user-disabled':
          return 'Tài khoản này đã bị vô hiệu hóa.';
        default:
          return 'Lỗi đăng nhập Google: ${e.message}';
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      if (googleUser != null) {
        await _googleSignIn.signOut();
      }
      return '❌ Lỗi mạng. Vui lòng kiểm tra kết nối và thử lại.';
    } catch (e) {
      print('❌ Google Sign In error: $e');
      if (googleUser != null) {
        await _googleSignIn.signOut();
      }
      return 'Đã xảy ra lỗi: $e';
    }
  }

  // ============================================
  // FACEBOOK SIGN IN

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
      print('Google user document created with single provider');

    } else {
      //  Existing user - CHECK before updating
      print('🟢 Updating existing user - checking existing provider');

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentProviders = List<String>.from(userData['providers'] ?? []);

      print('🔵 Current providers in Firestore: $currentProviders');

      // CRITICAL SAFETY CHECK: DO NOT overwrite password provider
      if (currentProviders.contains('password')) {
        print('🔴🔴🔴 SAFETY CHECK FAILED: User has password provider 🔴🔴🔴');
        print('🔴 This should have been blocked earlier!');
        print('🔴 Firebase may have merged accounts - ROLLING BACK...');

        // ROLLBACK STRATEGY: Unlink Google provider if it was added
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
  // SIGN OUT
  Future<void> signOut() async {
    print('🔵 Signing out...');

    // Stop notifications
    try {
      final notificationService = NotificationService();
      await notificationService.stopBackgroundNewsCheck();
      print('🔔 Stopped background notifications');
    } catch (e) {
      print('🟡 Warning: Could not stop notifications: $e');
    }

    // Clear login state
    await _saveLoginState(false, null);

    // Sign out from providers
    await _googleSignIn.signOut();
    await _auth.signOut();

    print('🟢 Signed out successfully');
  }
  // SEND PASSWORD RESET EMAIL (Legacy)
  Future<String?> sendPasswordResetEmailLegacy(String email) async {
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
  // GET USER DATA
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('🔴 Error getting user data: $e');
      return null;
    }
  }
  // CHECK EMAIL VERIFICATION STATUS
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

  // ============================================
  // SEND PASSWORD RESET EMAIL (Firebase Native)
  // ============================================
  /// Gửi email đặt lại mật khẩu sử dụng Firebase Authentication
  /// Không cần OTP, không cần Firestore, an toàn và đơn giản
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      print('🔵 Sending Firebase password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());

      print('🟢 Password reset email sent successfully');

      return {
        'success': true,
        'message': 'Email đặt lại mật khẩu đã được gửi',
      };
    } on FirebaseAuthException catch (e) {
      print('🔴 Firebase Auth error: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          return {
            'success': false,
            'message': 'Không tìm thấy tài khoản với email này',
          };
        case 'invalid-email':
          return {
            'success': false,
            'message': 'Email không hợp lệ',
          };
        default:
          return {
            'success': false,
            'message': 'Lỗi: ${e.message}',
          };
      }
    } catch (e) {
      print('🔴 Error sending password reset email: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: ${e.toString()}',
      };
    }
  }
}

