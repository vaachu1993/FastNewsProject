import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Save user data to Firestore với structure đầy đủ
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'displayName': name,
        'email': email,
        'photoURL': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'loginMethod': 'email',
        'emailVerified': true, // ✅ Đã xác thực qua OTP
        'verifiedAt': FieldValue.serverTimestamp(), // Thời điểm xác thực
        'verificationMethod': 'otp', // Phương thức xác thực
        'bookmarks': [], // Danh sách bookmark rỗng ban đầu
        // selectedTopics sẽ được thêm sau khi user chọn trong TopicsSelectionScreen
      });

      return null; // Success
    } on FirebaseAuthException catch (e) {
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
      return 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  // Sign in with email and password
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'wrong-password':
          return 'Mật khẩu không chính xác.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        case 'user-disabled':
          return 'Tài khoản này đã bị vô hiệu hóa.';
        default:
          return 'Đã xảy ra lỗi: ${e.message}';
      }
    } catch (e) {
      return 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  // Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign In...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('🔵 Google Sign In dialog completed');

      // If user cancels the sign-in
      if (googleUser == null) {
        print('🔴 User cancelled Google Sign In');
        return 'Đăng nhập bị hủy';
      }

      final email = googleUser.email;
      print('🔵 Google User: $email');

      // ✅ CHECK EMAIL TRƯỚC KHI SIGN IN (Quan trọng!)
      print('🔵 Checking if email exists in Firestore...');

      try {
        QuerySnapshot existingUsers = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingUsers.docs.isNotEmpty) {
          final existingUserDoc = existingUsers.docs.first;
          final existingData = existingUserDoc.data() as Map<String, dynamic>;
          final existingUid = existingUserDoc.id;
          final existingLoginMethod = existingData['loginMethod'] ?? '';

          print('🟡 Found existing user with email: $email');
          print('🟡 Display Name: ${existingData['displayName']}');
          print('🟡 Login Method: $existingLoginMethod');

          // ✅ CHỈ block nếu đã đăng ký bằng EMAIL/PASSWORD
          // Nếu đã đăng ký bằng Google trước đó → cho phép login lại
          if (existingLoginMethod == 'email') {
            // Email đã đăng ký bằng password - BLOCK Google sign in
            await _googleSignIn.signOut();
            print('🔴 Blocked Google sign in - email registered with password');
            return 'ACCOUNT_EXISTS|$email|${existingData['displayName']}|$existingUid';
          } else if (existingLoginMethod == 'google') {
            // Email đã đăng ký bằng Google trước đó - CHO PHÉP login lại
            print('🟢 Email already registered with Google - allowing sign in');
            // Không return, tiếp tục flow bình thường
          }
        }
      } catch (firestoreError) {
        print('⚠️ Firestore check error (continuing anyway): $firestoreError');
        // Nếu Firestore lỗi, vẫn cho phép đăng nhập Google
      }

      // ✅ Email chưa tồn tại - Tiếp tục sign in
      print('🟢 Email not found - proceeding with Google sign in');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('🔵 Got authentication tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('🔵 Created Firebase credential');

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('🟢 Firebase sign in successful: ${userCredential.user?.email}');

      // User mới hoàn toàn - tạo document mới
      print('🟢 New Google user - creating document');

      try {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'displayName': userCredential.user?.displayName ?? 'Google User',
          'email': email,
          'photoURL': userCredential.user?.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'loginMethod': 'google',
          'emailVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
          'verificationMethod': 'google',
          'bookmarks': [],
        }, SetOptions(merge: true));

        // Update last login
        await _firestore.collection('users').doc(userCredential.user?.uid).update({
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        print('🟢 User document created successfully');
      } catch (firestoreError) {
        print('⚠️ Firestore write error: $firestoreError');
        // User đã login Firebase Auth thành công
        // Chỉ việc tạo document bị lỗi (có thể do Firestore rules)
        // Vẫn return null để cho user vào app
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('🔴 FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'Email này đã được đăng ký. Vui lòng đăng nhập bằng email/password hoặc liên hệ hỗ trợ.';
        case 'invalid-credential':
          return 'Thông tin xác thực không hợp lệ.';
        case 'operation-not-allowed':
          return 'Phương thức đăng nhập này chưa được kích hoạt.';
        case 'user-disabled':
          return 'Tài khoản này đã bị vô hiệu hóa.';
        default:
          return 'Đã xảy ra lỗi: ${e.message}';
      }
    } catch (e) {
      print('🔴 Error in Google Sign In: $e');
      return 'Đã xảy ra lỗi: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Sign out from Google
    await _auth.signOut(); // Sign out from Firebase
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        default:
          return 'Đã xảy ra lỗi: ${e.message}';
      }
    } catch (e) {
      return 'Đã xảy ra l���i không xác định: $e';
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Check if user's email is verified
  Future<bool> isEmailVerified(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?['emailVerified'] ?? false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  // Get verification info
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
      print('Error getting verification info: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoUrl,
  }) async {
    User? user = currentUser;
    if (user != null) {
      if (name != null) {
        await user.updateDisplayName(name);
        await _firestore.collection('users').doc(user.uid).update({'displayName': name});
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
    }
  }
}

