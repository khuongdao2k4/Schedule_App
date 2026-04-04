import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 🔥 Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      // Chọn tài khoản Google
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) {
        // Người dùng hủy đăng nhập
        return null;
      }

      // Lấy thông tin xác thực
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Tạo credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập Firebase
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // 🔥 Đăng xuất
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 🔥 Lấy user hiện tại
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}