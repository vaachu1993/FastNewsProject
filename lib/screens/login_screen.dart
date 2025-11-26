import 'package:fastnews/screens/signup_screen.dart';
import 'package:fastnews/screens/topics_selection_screen.dart';
import 'package:fastnews/screens/email_login_screen.dart';
import 'package:fastnews/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isGoogleLoading = false;

  // Handle Google Sign In
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      String? result = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (result == null) {
        // Google login thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập Google thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        await _checkAndNavigate();
      } else {
        // Hiển thị lỗi (bao gồm provider conflict errors)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: result.contains('❌') ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }


  // Check if user has selected topics and navigate accordingly
  // ⚡ OPTIMIZED: Reduced Firestore queries for faster navigation
  Future<void> _checkAndNavigate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ⚡ Use cache from server to reduce latency
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.serverAndCache));

        if (!mounted) return;

        // Kiểm tra xem user đã có selectedTopics chưa
        if (userDoc.exists && userDoc.data()?['selectedTopics'] != null) {
          final topics = userDoc.data()?['selectedTopics'] as List?;
          if (topics != null && topics.isNotEmpty) {
            // Đã chọn topics rồi -> đi thẳng đến MainScreen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
            return;
          }
        }

        // Chưa chọn topics -> đi đến TopicsSelectionScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const TopicsSelectionScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('🟡 Navigation warning: $e');
      if (!mounted) return;
      // Nếu có lỗi, vẫn cho đi đến TopicsSelectionScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const TopicsSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                _buildLogo(),

                const SizedBox(height: 20),

                // App Name
                Text(
                  'FastNews',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF2C2C2C),
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Welcome Text
                Text(
                  "Chào mừng! Hãy đăng nhập vào tài khoản của bạn!",
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF808080),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 50),

                // Google Button (Full Width)
                _buildGoogleButton(context),

                const SizedBox(height: 32),

                // Or divider
                Row(
                  children: [
                    Expanded(child: Divider(color: isDarkMode ? Colors.grey.shade700 : const Color(0xFFE0E0E0))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'hoặc',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF808080),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: isDarkMode ? Colors.grey.shade700 : const Color(0xFFE0E0E0))),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign in with password button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Email Login Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailLoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A7D3C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Đăng nhập bằng mật khẩu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign up text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Chưa có tài khoản?  ",
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF2C2C2C),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to sign up (replace to avoid back button)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(
                          color: Color(0xFF5A7D3C),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          // Yellow part
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFFF5D547), const Color(0xFFD4A528)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),
          // Green part
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF6B9B4D), const Color(0xFF4A7A32)],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildGoogleButton(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDarkMode ? const Color(0xFF2A2740) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  // Icon positioned on the left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Centered text
                  Text(
                    'Tiếp tục với Google',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : const Color(0xFF2C2C2C),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
