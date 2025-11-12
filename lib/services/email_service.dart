import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  // ✅ Lấy cấu hình SMTP từ .env file (BẢO MẬT)
  static String get _username => dotenv.env['SMTP_USERNAME'] ?? '';
  static String get _password => dotenv.env['SMTP_PASSWORD'] ?? '';

  // Optional: Custom SMTP server (mặc định dùng Gmail)
  static String get _host => dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
  static int get _port => int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;

  // Nếu dùng Gmail, cần tạo App Password tại: https://myaccount.google.com/apppasswords
  // Hoặc có thể dùng các dịch vụ SMTP khác như SendGrid, Mailgun, AWS SES...

  /// Gửi email OTP
  Future<bool> sendOtpEmail({
    required String recipientEmail,
    required String otp,
  }) async {
    try {
      // Cấu hình SMTP server (Gmail)
      final smtpServer = gmail(_username, _password);

      // Tạo nội dung email
      final message = Message()
        ..from = Address(_username, 'FastNews')
        ..recipients.add(recipientEmail)
        ..subject = 'Mã xác thực OTP - FastNews'
        ..html = _buildOtpEmailHtml(otp);

      // Gửi email
      final sendReport = await send(message, smtpServer);
      print('Email sent successfully: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Error sending OTP email: $e');
      return false;
    }
  }

  /// Tạo HTML template cho email OTP
  String _buildOtpEmailHtml(String otp) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .container {
          background-color: #f9f9f9;
          border-radius: 10px;
          padding: 30px;
          box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .header {
          text-align: center;
          color: #2196F3;
          margin-bottom: 30px;
        }
        .otp-box {
          background-color: #2196F3;
          color: white;
          font-size: 32px;
          font-weight: bold;
          text-align: center;
          padding: 20px;
          border-radius: 8px;
          letter-spacing: 8px;
          margin: 20px 0;
        }
        .info {
          background-color: #fff3cd;
          border-left: 4px solid #ffc107;
          padding: 15px;
          margin: 20px 0;
        }
        .footer {
          text-align: center;
          color: #666;
          font-size: 12px;
          margin-top: 30px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1 class="header">🔐 FastNews - Xác Thực Tài Khoản</h1>
        
        <p>Xin chào,</p>
        
        <p>Bạn đang thực hiện đăng ký tài khoản FastNews. Đây là mã OTP xác thực của bạn:</p>
        
        <div class="otp-box">$otp</div>
        
        <div class="info">
          <strong>⚠️ Lưu ý:</strong>
          <ul>
            <li>Mã OTP có hiệu lực trong <strong>5 phút</strong></li>
            <li>Không chia sẻ mã này với bất kỳ ai</li>
            <li>Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email</li>
          </ul>
        </div>
        
        <p>Nhập mã OTP trên vào ứng dụng để hoàn tất đăng ký.</p>
        
        <p>Trân trọng,<br><strong>Đội ngũ FastNews</strong></p>
        
        <div class="footer">
          <p>Email này được gửi tự động, vui lòng không trả lời.</p>
          <p>© 2025 FastNews. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Gửi email chào mừng sau khi đăng ký thành công
  Future<bool> sendWelcomeEmail({
    required String recipientEmail,
    required String userName,
  }) async {
    try {
      final smtpServer = gmail(_username, _password);

      final message = Message()
        ..from = Address(_username, 'FastNews')
        ..recipients.add(recipientEmail)
        ..subject = 'Chào mừng đến với FastNews! 🎉'
        ..html = _buildWelcomeEmailHtml(userName);

      final sendReport = await send(message, smtpServer);
      print('Welcome email sent successfully: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Error sending welcome email: $e');
      return false;
    }
  }

  String _buildWelcomeEmailHtml(String userName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .container {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 10px;
          padding: 40px;
          color: white;
        }
        .header {
          text-align: center;
          margin-bottom: 30px;
        }
        .content {
          background-color: white;
          color: #333;
          padding: 30px;
          border-radius: 8px;
        }
        .button {
          display: inline-block;
          background-color: #2196F3;
          color: white;
          padding: 12px 30px;
          text-decoration: none;
          border-radius: 5px;
          margin: 20px 0;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🎉 Chào mừng đến với FastNews!</h1>
        </div>
        
        <div class="content">
          <p>Xin chào <strong>$userName</strong>,</p>
          
          <p>Cảm ơn bạn đã đăng ký tài khoản FastNews! Chúng tôi rất vui khi có bạn tham gia cộng đồng.</p>
          
          <h3>🚀 Bắt đầu khám phá:</h3>
          <ul>
            <li>📰 Đọc tin tức mới nhất từ các nguồn tin uy tín</li>
            <li>🔖 Lưu các bài viết yêu thích của bạn</li>
            <li>🎯 Khám phá các chủ đề mà bạn quan tâm</li>
            <li>🔍 Tìm kiếm tin tức theo nhu cầu</li>
          </ul>
          
          <p>Hãy bắt đầu trải nghiệm ngay hôm nay!</p>
          
          <p>Nếu bạn có bất kỳ câu hỏi nào, đừng ngần ngại liên hệ với chúng tôi.</p>
          
          <p>Chúc bạn có trải nghiệm tuyệt vời!</p>
          
          <p>Trân trọng,<br><strong>Đội ngũ FastNews</strong></p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}

