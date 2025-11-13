// ignore_for_file: avoid_print

/// ERROR HANDLING GUIDE FOR SINGLE-PROVIDER AUTH
///
/// File này cung cấp hướng dẫn xử lý error messages trong UI
/// để hiển thị thông báo thân thiện cho user

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthErrorHandler {
  /// Parse error message từ AuthService và hiển thị UI phù hợp
  static void showAuthError(BuildContext context, String? errorMessage) {
    if (errorMessage == null) return; // No error

    // Detect provider conflict errors
    if (errorMessage.contains('❌')) {
      _showProviderConflictDialog(context, errorMessage);
    } else {
      _showSimpleErrorDialog(context, errorMessage);
    }
  }

  /// Dialog cho provider conflict (special case)
  static void _showProviderConflictDialog(
    BuildContext context,
    String errorMessage,
  ) {
    String title = 'Phương Thức Đăng Nhập Không Đúng';
    String message = errorMessage.replaceAll('❌ ', '');
    IconData icon = Icons.warning_amber_rounded;
    Color iconColor = Colors.orange;

    // Detect specific conflict type
    if (errorMessage.contains('đăng ký bằng Google')) {
      icon = Icons.login;
      iconColor = Colors.blue;
    } else if (errorMessage.contains('đăng ký bằng Email/Mật khẩu')) {
      icon = Icons.email;
      iconColor = Colors.blue;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mỗi email chỉ có thể sử dụng một phương thức đăng nhập duy nhất.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã Hiểu'),
          ),
        ],
      ),
    );
  }

  /// Simple error dialog cho các lỗi khác
  static void _showSimpleErrorDialog(
    BuildContext context,
    String errorMessage,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Lỗi Đăng Nhập'),
          ],
        ),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Show SnackBar thay vì Dialog (alternative)
  static void showAuthErrorSnackBar(
    BuildContext context,
    String? errorMessage,
  ) {
    if (errorMessage == null) return;

    Color bgColor = Colors.red;
    IconData icon = Icons.error_outline;

    // Provider conflict → orange color
    if (errorMessage.contains('❌')) {
      bgColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage.replaceAll('❌ ', ''),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

/// ============================================
/// USAGE EXAMPLES
/// ============================================

/// Example 1: Sign In Screen - Email/Password
class EmailLoginExample extends StatelessWidget {
  final AuthService authService = AuthService();

  EmailLoginExample({super.key});

  Future<void> _handleEmailLogin(BuildContext context) async {
    String? error = await authService.signInWithEmail(
      email: 'test@example.com',
      password: 'password123',
    );

    if (error != null) {
      if (!context.mounted) return;
      // Show error with proper UI
      AuthErrorHandler.showAuthError(context, error);
    } else {
      // Success - navigate to home
      print('Login successful!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder
  }
}

/// Example 2: Sign In Screen - Google
class GoogleLoginExample extends StatelessWidget {
  final AuthService authService = AuthService();

  GoogleLoginExample({super.key});

  Future<void> _handleGoogleLogin(BuildContext context) async {
    String? error = await authService.signInWithGoogle();

    if (error != null) {
      if (!context.mounted) return;
      // Show error with proper UI
      AuthErrorHandler.showAuthError(context, error);
    } else {
      // Success - navigate to home
      print('Google login successful!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder
  }
}

/// ============================================
/// ERROR MESSAGE PATTERNS
/// ============================================

class ErrorPatterns {
  // Provider conflict errors (need special UI)
  static const List<String> providerConflictErrors = [
    '❌ Email này đã được đăng ký bằng Google',
    '❌ Email này đã được đăng ký bằng Email/Mật khẩu',
    '❌ Email này đã được đăng ký bằng phương thức khác',
  ];

  // Regular auth errors
  static const List<String> regularAuthErrors = [
    'Không tìm thấy tài khoản với email này',
    'Mật khẩu không chính xác',
    'Email không hợp lệ',
    'Tài khoản này đã bị vô hiệu hóa',
    'Đăng nhập bị hủy',
  ];

  /// Check if error is a provider conflict
  static bool isProviderConflict(String errorMessage) {
    return errorMessage.contains('❌');
  }

  /// Get suggested action based on error
  static String getSuggestedAction(String errorMessage) {
    if (errorMessage.contains('đăng ký bằng Google')) {
      return 'Vui lòng đăng nhập bằng Google thay vì email/mật khẩu';
    } else if (errorMessage.contains('đăng ký bằng Email/Mật khẩu')) {
      return 'Vui lòng đăng nhập bằng email/mật khẩu thay vì Google';
    } else if (errorMessage.contains('Mật khẩu không chính xác')) {
      return 'Kiểm tra lại mật khẩu hoặc dùng "Quên mật khẩu"';
    } else if (errorMessage.contains('Không tìm thấy tài khoản')) {
      return 'Vui lòng đăng ký tài khoản mới';
    }
    return 'Vui lòng thử lại';
  }
}

/// ============================================
/// UI WIDGET FOR LOGIN SCREEN
/// ============================================

class LoginMethodInfo extends StatelessWidget {
  const LoginMethodInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lưu ý: Mỗi email chỉ có thể sử dụng một phương thức đăng nhập (Email/Password hoặc Google).',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================
/// TESTING ERROR MESSAGES
/// ============================================

void testErrorMessages() {
  print('=== Testing Error Message Detection ===\n');

  final testCases = [
    '❌ Email này đã được đăng ký bằng Google',
    '❌ Email này đã được đăng ký bằng Email/Mật khẩu',
    'Mật khẩu không chính xác',
    'Không tìm thấy tài khoản với email này',
  ];

  for (var error in testCases) {
    print('Error: $error');
    print('Is Conflict: ${ErrorPatterns.isProviderConflict(error)}');
    print('Suggested: ${ErrorPatterns.getSuggestedAction(error)}');
    print('---');
  }
}

// Uncomment to run test
// void main() => testErrorMessages();

