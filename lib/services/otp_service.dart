import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'email_service.dart';

class OtpService {
  final EmailService _emailService = EmailService();

  // Thời gian hết hạn OTP (5 phút)
  static const int otpExpiryMinutes = 5;

  /// Tạo mã OTP 6 chữ số
  String _generateOtp() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }

  /// Gửi OTP đến email
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      // Tạo OTP
      final otp = _generateOtp();
      final expiryTime = DateTime.now().add(Duration(minutes: otpExpiryMinutes));

      // Lưu OTP vào SharedPreferences (tạm thời)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('otp_$email', otp);
      await prefs.setString('otp_expiry_$email', expiryTime.toIso8601String());

      print('Generated OTP for $email: $otp (expires at $expiryTime)');

      // Gửi OTP qua email
      bool emailSent = await _emailService.sendOtpEmail(
        recipientEmail: email,
        otp: otp,
      );

      if (emailSent) {
        return {
          'success': true,
          'message': 'Mã OTP đã được gửi đến email của bạn',
          'expiryTime': expiryTime,
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể gửi email OTP. Vui lòng thử lại sau.',
        };
      }
    } catch (e) {
      print('Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  /// Xác thực OTP
  Future<Map<String, dynamic>> verifyOtp(String email, String enteredOtp) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Lấy OTP và thời gian hết hạn đã lưu
      final savedOtp = prefs.getString('otp_$email');
      final expiryTimeStr = prefs.getString('otp_expiry_$email');

      // Kiểm tra OTP có tồn tại không
      if (savedOtp == null || expiryTimeStr == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy mã OTP. Vui lòng yêu cầu gửi lại.',
        };
      }

      // Kiểm tra OTP đã hết hạn chưa
      final expiryTime = DateTime.parse(expiryTimeStr);
      if (DateTime.now().isAfter(expiryTime)) {
        // Xóa OTP đã hết hạn
        await _clearOtp(email);
        return {
          'success': false,
          'message': 'Mã OTP đã hết hạn. Vui lòng yêu cầu gửi lại.',
        };
      }

      // Kiểm tra OTP có khớp không
      if (savedOtp == enteredOtp) {
        // Xóa OTP sau khi xác thực thành công
        await _clearOtp(email);
        return {
          'success': true,
          'message': 'Xác thực thành công!',
        };
      } else {
        return {
          'success': false,
          'message': 'Mã OTP không chính xác. Vui lòng thử lại.',
        };
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  /// Xóa OTP đã lưu
  Future<void> _clearOtp(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('otp_$email');
    await prefs.remove('otp_expiry_$email');
  }

  /// Gửi lại OTP (có thể giới hạn số lần gửi)
  Future<Map<String, dynamic>> resendOtp(String email) async {
    // Xóa OTP cũ
    await _clearOtp(email);

    // Gửi OTP mới
    return await sendOtp(email);
  }

  /// Kiểm tra thời gian còn lại của OTP
  Future<Duration?> getRemainingTime(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryTimeStr = prefs.getString('otp_expiry_$email');

      if (expiryTimeStr == null) return null;

      final expiryTime = DateTime.parse(expiryTimeStr);
      final now = DateTime.now();

      if (now.isAfter(expiryTime)) {
        await _clearOtp(email);
        return null;
      }

      return expiryTime.difference(now);
    } catch (e) {
      print('Error getting remaining time: $e');
      return null;
    }
  }

  /// Gửi email chào mừng sau khi đăng ký thành công
  Future<bool> sendWelcomeEmail(String email, String userName) async {
    try {
      return await _emailService.sendWelcomeEmail(
        recipientEmail: email,
        userName: userName,
      );
    } catch (e) {
      print('Error sending welcome email: $e');
      return false;
    }
  }
}

