import 'package:flutter/material.dart';
import '../widgets/localization_provider.dart';
import '../utils/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.privacyPolicy,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated
            Text(
              currentLanguage == 'vi'
                  ? 'Cập nhật lần cuối: 20/11/2025'
                  : 'Last Updated: November 20, 2025',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              context,
              currentLanguage == 'vi' ? 'Giới thiệu' : 'Introduction',
              currentLanguage == 'vi'
                  ? 'FastNews cam kết bảo vệ quyền riêng tư của bạn. Chính sách bảo mật này giải thích cách chúng tôi thu thập, sử dụng và bảo vệ thông tin cá nhân của bạn khi sử dụng ứng dụng.'
                  : 'FastNews is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and protect your personal information when using our application.',
            ),
            const SizedBox(height: 20),

            // Information We Collect
            _buildSection(
              context,
              currentLanguage == 'vi' ? '1. Thông tin chúng tôi thu thập' : '1. Information We Collect',
              currentLanguage == 'vi'
                  ? '''Chúng tôi có thể thu thập các loại thông tin sau:

• Thông tin tài khoản: Email, tên hiển thị, ảnh đại diện
• Thông tin sử dụng: Bài viết đã đọc, bookmark, sở thích
• Thông tin thiết bị: Loại thiết bị, hệ điều hành, ID thiết bị
• Dữ liệu phân tích: Thời gian sử dụng, tương tác với ứng dụng'''
                  : '''We may collect the following types of information:

• Account information: Email, display name, profile picture
• Usage information: Read articles, bookmarks, preferences
• Device information: Device type, operating system, device ID
• Analytics data: Usage time, app interactions''',
            ),
            const SizedBox(height: 20),

            // How We Use Information
            _buildSection(
              context,
              currentLanguage == 'vi' ? '2. Cách chúng tôi sử dụng thông tin' : '2. How We Use Information',
              currentLanguage == 'vi'
                  ? '''Thông tin của bạn được sử dụng để:

• Cung cấp và cải thiện dịch vụ
• Cá nhân hóa trải nghiệm người dùng
• Gửi thông báo về tin tức quan trọng
• Phân tích và cải thiện hiệu suất ứng dụng
• Đảm bảo an toàn và bảo mật
• Tuân thủ nghĩa vụ pháp lý'''
                  : '''Your information is used to:

• Provide and improve our service
• Personalize user experience
• Send notifications about important news
• Analyze and improve app performance
• Ensure safety and security
• Comply with legal obligations''',
            ),
            const SizedBox(height: 20),

            // Data Storage
            _buildSection(
              context,
              currentLanguage == 'vi' ? '3. Lưu trữ dữ liệu' : '3. Data Storage',
              currentLanguage == 'vi'
                  ? '''Dữ liệu của bạn được lưu trữ an toàn trên:

• Firebase Cloud Firestore (Google Cloud Platform)
• Dữ liệu được mã hóa khi truyền và lưu trữ
• Tuân thủ các tiêu chuẩn bảo mật quốc tế
• Backup định kỳ để đảm bảo an toàn dữ liệu'''
                  : '''Your data is securely stored on:

• Firebase Cloud Firestore (Google Cloud Platform)
• Data is encrypted during transmission and storage
• Complies with international security standards
• Regular backups to ensure data safety''',
            ),
            const SizedBox(height: 20),

            // Third-Party Services
            _buildSection(
              context,
              currentLanguage == 'vi' ? '4. Dịch vụ bên thứ ba' : '4. Third-Party Services',
              currentLanguage == 'vi'
                  ? '''Chúng tôi sử dụng các dịch vụ bên thứ ba sau:

• Google Firebase: Xác thực và lưu trữ dữ liệu
• Google Sign-In: Đăng nhập bằng tài khoản Google

• Analytics: Phân tích hành vi người dùng

Các dịch vụ này có chính sách bảo mật riêng.'''
                  : '''We use the following third-party services:

• Google Firebase: Authentication and data storage
• Google Sign-In: Sign in with Google account

• Analytics: User behavior analysis

These services have their own privacy policies.''',
            ),
            const SizedBox(height: 20),

            // Your Rights
            _buildSection(
              context,
              currentLanguage == 'vi' ? '5. Quyền của bạn' : '5. Your Rights',
              currentLanguage == 'vi'
                  ? '''Bạn có các quyền sau:

• Truy cập dữ liệu cá nhân của bạn
• Chỉnh sửa hoặc cập nhật thông tin
• Xóa tài khoản và dữ liệu
• Từ chối thu thập dữ liệu không bắt buộc
• Xuất dữ liệu của bạn
• Khiếu nại về xử lý dữ liệu'''
                  : '''You have the following rights:

• Access your personal data
• Edit or update information
• Delete account and data
• Opt-out of non-essential data collection
• Export your data
• File complaints about data processing''',
            ),
            const SizedBox(height: 20),

            // Data Retention
            _buildSection(
              context,
              currentLanguage == 'vi' ? '6. Thời gian lưu trữ' : '6. Data Retention',
              currentLanguage == 'vi'
                  ? '''• Dữ liệu tài khoản: Lưu trữ cho đến khi bạn xóa tài khoản
• Dữ liệu sử dụng: Lưu trữ tối đa 2 năm
• Dữ liệu phân tích: Được ẩn danh sau 6 tháng
• Backup: Xóa hoàn toàn sau 30 ngày kể từ khi xóa tài khoản'''
                  : '''• Account data: Stored until you delete your account
• Usage data: Stored for maximum 2 years
• Analytics data: Anonymized after 6 months
• Backups: Completely deleted 30 days after account deletion''',
            ),
            const SizedBox(height: 20),

            // Security
            _buildSection(
              context,
              currentLanguage == 'vi' ? '7. Bảo mật' : '7. Security',
              currentLanguage == 'vi'
                  ? '''Chúng tôi áp dụng các biện pháp bảo mật:

• Mã hóa dữ liệu SSL/TLS
• Xác thực hai yếu tố (2FA)
• Giám sát bảo mật 24/7
• Cập nhật bảo mật định kỳ
• Kiểm tra bảo mật độc lập
• Đào tạo nhân viên về bảo mật'''
                  : '''We implement security measures:

• SSL/TLS data encryption
• Two-factor authentication (2FA)
• 24/7 security monitoring
• Regular security updates
• Independent security audits
• Staff security training''',
            ),
            const SizedBox(height: 20),

            // Children's Privacy
            _buildSection(
              context,
              currentLanguage == 'vi' ? '8. Quyền riêng tư trẻ em' : '8. Children\'s Privacy',
              currentLanguage == 'vi'
                  ? 'Ứng dụng này không nhắm đến trẻ em dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin từ trẻ em. Nếu bạn phát hiện trẻ em đã cung cấp thông tin, vui lòng liên hệ với chúng tôi để xóa dữ liệu.'
                  : 'This app is not intended for children under 13 years old. We do not knowingly collect information from children. If you discover a child has provided information, please contact us to delete the data.',
            ),
            const SizedBox(height: 20),

            // Changes to Privacy Policy
            _buildSection(
              context,
              currentLanguage == 'vi' ? '9. Thay đổi chính sách' : '9. Changes to Privacy Policy',
              currentLanguage == 'vi'
                  ? 'Chúng tôi có thể cập nhật chính sách này theo thời gian. Thay đổi quan trọng sẽ được thông báo qua ứng dụng hoặc email. Việc tiếp tục sử dụng sau khi có thay đổi đồng nghĩa với việc chấp nhận chính sách mới.'
                  : 'We may update this policy over time. Important changes will be notified via the app or email. Continued use after changes means acceptance of the new policy.',
            ),
            const SizedBox(height: 20),

            // Contact
            _buildSection(
              context,
              currentLanguage == 'vi' ? '10. Liên hệ' : '10. Contact',
              currentLanguage == 'vi'
                  ? '''Nếu có câu hỏi về chính sách bảo mật:

📧 Email: privacy@fastnews.com
📱 Hotline: 1900-FASTNEWS
🌐 Website: www.fastnews.com/privacy
📍 Địa chỉ: 123 Đường ABC, Quận 1, TP.HCM'''
                  : '''If you have questions about privacy policy:

📧 Email: privacy@fastnews.com
📱 Hotline: 1900-FASTNEWS
🌐 Website: www.fastnews.com/privacy
📍 Address: 123 ABC Street, District 1, Ho Chi Minh City''',
            ),
            const SizedBox(height: 20),

            // GDPR Compliance (for European users)
            _buildSection(
              context,
              currentLanguage == 'vi' ? '11. Tuân thủ GDPR' : '11. GDPR Compliance',
              currentLanguage == 'vi'
                  ? '''Đối với người dùng ở EU, chúng tôi tuân thủ GDPR:

• Quyền được quên (Right to be forgotten)
• Quyền chuyển dữ liệu (Data portability)
• Quyền hạn chế xử lý
• Thông báo vi phạm dữ liệu trong 72 giờ
• Bảo vệ dữ liệu từ thiết kế
• Đánh giá tác động bảo vệ dữ liệu'''
                  : '''For EU users, we comply with GDPR:

• Right to be forgotten
• Data portability rights
• Right to restrict processing
• Data breach notification within 72 hours
• Privacy by design
• Data protection impact assessments''',
            ),
            const SizedBox(height: 40),

            // Agreement notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentLanguage == 'vi'
                          ? 'Bằng việc sử dụng FastNews, bạn đồng ý với chính sách bảo mật này.'
                          : 'By using FastNews, you agree to this privacy policy.',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

