import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'bookmarks': [], // Danh sách bookmark rỗng ban đầu
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
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in
      if (googleUser == null) {
        return 'Đăng nhập bị hủy';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Save new user data to Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'name': userCredential.user?.displayName ?? 'Google User',
          'email': userCredential.user?.email ?? '',
          'photoUrl': userCredential.user?.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'loginMethod': 'google',
        });
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'Tài khoản đã tồn tại với phương thức đăng nhập khác.';
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
      print('Error in Google Sign In: $e');
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

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoUrl,
  }) async {
    User? user = currentUser;
    if (user != null) {
      if (name != null) {
        await user.updateDisplayName(name);
        await _firestore.collection('users').doc(user.uid).update({'name': name});
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
    }
  }
}

