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

      print('🔵 Google User: ${googleUser.email}');

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

      // Check if this is a new user hoặc user chưa có trong Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user?.uid).get();

      if (!userDoc.exists || userCredential.additionalUserInfo?.isNewUser == true) {
        // Save new user data to Firestore với structure đầy đủ
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'displayName': userCredential.user?.displayName ?? 'Google User',
          'email': userCredential.user?.email ?? '',
          'photoURL': userCredential.user?.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'loginMethod': 'google',
          'bookmarks': [],
          // selectedTopics sẽ được thêm sau khi user chọn trong TopicsSelectionScreen
        }, SetOptions(merge: true));
      } else {
        // User đã tồn tại, chỉ update timestamp
        await _firestore.collection('users').doc(userCredential.user?.uid).update({
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
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

