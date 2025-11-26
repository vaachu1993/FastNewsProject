import 'package:flutter/material.dart';
import '../widgets/localization_provider.dart';
import '../utils/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
          loc.help,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Welcome message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    currentLanguage == 'vi'
                        ? 'Chúng tôi sẵn sàng giúp bạn!'
                        : 'We\'re here to help!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FAQ Section
          Text(
            currentLanguage == 'vi' ? 'Câu hỏi thường gặp' : 'Frequently Asked Questions',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // FAQ Items
          _buildFAQItem(
            context,
            currentLanguage == 'vi' ? 'Làm sao để đăng ký tài khoản?' : 'How do I create an account?',
            currentLanguage == 'vi'
                ? 'Bạn có thể đăng ký bằng email hoặc Google. Chỉ cần nhấn nút "Đăng nhập" và chọn phương thức đăng ký phù hợp.'
                : 'You can sign up with email or Google. Just tap "Login" and choose your preferred sign-up method.',
            Icons.person_add_outlined,
          ),
          _buildFAQItem(
            context,
            currentLanguage == 'vi' ? 'Làm sao để lưu bài viết?' : 'How do I save articles?',
            currentLanguage == 'vi'
                ? 'Nhấn vào biểu tượng bookmark (dấu trang) trên bài viết để lưu. Bạn có thể xem các bài đã lưu trong tab "Đã lưu".'
                : 'Tap the bookmark icon on any article to save it. You can view saved articles in the "Saved" tab.',
            Icons.bookmark_outline,
          ),
          _buildFAQItem(
            context,
            currentLanguage == 'vi' ? 'Làm sao để bật thông báo?' : 'How do I enable notifications?',
            currentLanguage == 'vi'
                ? 'Vào Cài đặt > Thông báo và bật công tắc. Bạn sẽ nhận được thông báo về tin tức quan trọng.'
                : 'Go to Settings > Notifications and toggle it on. You\'ll receive notifications about important news.',
            Icons.notifications_outlined,
          ),
          _buildFAQItem(
            context,
            currentLanguage == 'vi' ? 'Làm sao để đổi ngôn ngữ?' : 'How do I change language?',
            currentLanguage == 'vi'
                ? 'Vào Cài đặt > Ngôn ngữ và chọn Tiếng Việt hoặc English. Giao diện sẽ tự động cập nhật.'
                : 'Go to Settings > Language and select Vietnamese or English. The interface will update automatically.',
            Icons.language_outlined,
          ),
          _buildFAQItem(
            context,
            currentLanguage == 'vi' ? 'Làm sao để xóa tài khoản?' : 'How do I delete my account?',
            currentLanguage == 'vi'
                ? 'Vào Hồ sơ > Cài đặt tài khoản > Xóa tài khoản. Lưu ý: Hành động này không thể hoàn tác.'
                : 'Go to Profile > Account Settings > Delete Account. Note: This action cannot be undone.',
            Icons.delete_outline,
          ),
          _buildFAQItem(
            context,
            currentLanguage == 'vi' ? 'Làm sao để bật chế độ tối?' : 'How do I enable dark mode?',
            currentLanguage == 'vi'
                ? 'Vào Cài đặt > Chế độ tối và bật công tắc. Giao diện sẽ chuyển sang màu tối dễ nhìn hơn.'
                : 'Go to Settings > Dark Mode and toggle it on. The interface will switch to a darker theme.',
            Icons.dark_mode_outlined,
          ),

          const SizedBox(height: 32),

          // Contact Support Section
          Text(
            currentLanguage == 'vi' ? 'Liên hệ hỗ trợ' : 'Contact Support',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildContactItem(
            context,
            Icons.email_outlined,
            'Email',
            'support@fastnews.com',
            currentLanguage == 'vi' ? 'Phản hồi trong 24 giờ' : 'Response within 24 hours',
          ),
          _buildContactItem(
            context,
            Icons.phone_outlined,
            currentLanguage == 'vi' ? 'Hotline' : 'Phone',
            '1900-FASTNEWS',
            currentLanguage == 'vi' ? 'Hỗ trợ 24/7' : '24/7 Support',
          ),
          _buildContactItem(
            context,
            Icons.chat_outlined,
            currentLanguage == 'vi' ? 'Chat trực tuyến' : 'Live Chat',
            currentLanguage == 'vi' ? 'Trò chuyện ngay' : 'Chat now',
            currentLanguage == 'vi' ? 'Sẵn sàng 8:00 - 22:00' : 'Available 8:00 - 22:00',
          ),
          _buildContactItem(
            context,
            Icons.location_on_outlined,
            currentLanguage == 'vi' ? 'Văn phòng' : 'Office',
            '123 ABC Street, District 1, HCMC',
            currentLanguage == 'vi' ? 'Giờ làm việc: 8:00 - 17:00' : 'Business hours: 8:00 - 17:00',
          ),

          const SizedBox(height: 32),

          // Quick Links
          Text(
            currentLanguage == 'vi' ? 'Liên kết hữu ích' : 'Useful Links',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildLinkItem(
            context,
            Icons.description_outlined,
            currentLanguage == 'vi' ? 'Điều khoản dịch vụ' : 'Terms of Service',
            () {
              // Navigate to terms screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(currentLanguage == 'vi'
                      ? 'Mở điều khoản dịch vụ...'
                      : 'Opening terms of service...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          _buildLinkItem(
            context,
            Icons.privacy_tip_outlined,
            currentLanguage == 'vi' ? 'Chính sách bảo mật' : 'Privacy Policy',
            () {
              // Navigate to privacy screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(currentLanguage == 'vi'
                      ? 'Mở chính sách bảo mật...'
                      : 'Opening privacy policy...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          _buildLinkItem(
            context,
            Icons.info_outlined,
            currentLanguage == 'vi' ? 'Về chúng tôi' : 'About Us',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(currentLanguage == 'vi'
                      ? 'FastNews - Ứng dụng đọc tin tức hàng đầu Việt Nam'
                      : 'FastNews - Leading news app in Vietnam'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          _buildLinkItem(
            context,
            Icons.bug_report_outlined,
            currentLanguage == 'vi' ? 'Báo lỗi' : 'Report a Bug',
            () {
              _showReportDialog(context, currentLanguage);
            },
          ),
          _buildLinkItem(
            context,
            Icons.star_outlined,
            currentLanguage == 'vi' ? 'Đánh giá ứng dụng' : 'Rate the App',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(currentLanguage == 'vi'
                      ? 'Cảm ơn bạn! Chuyển đến cửa hàng ứng dụng...'
                      : 'Thank you! Redirecting to app store...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Tips Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      currentLanguage == 'vi' ? 'Mẹo sử dụng' : 'Tips',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  context,
                  currentLanguage == 'vi'
                      ? 'Vuốt sang trái/phải để chuyển danh mục tin tức'
                      : 'Swipe left/right to switch news categories',
                ),
                _buildTipItem(
                  context,
                  currentLanguage == 'vi'
                      ? 'Nhấn giữ bài viết để chia sẻ nhanh'
                      : 'Long press article to quick share',
                ),
                _buildTipItem(
                  context,
                  currentLanguage == 'vi'
                      ? 'Kéo xuống để làm mới danh sách tin'
                      : 'Pull down to refresh news list',
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Version info
          Center(
            child: Column(
              children: [
                Text(
                  'FastNews v1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2025 FastNews. All rights reserved.',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2740)
          : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text(
            question,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2740)
          : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2740)
          : Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: Theme.of(context).iconTheme.color, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).textTheme.bodySmall?.color,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.green, fontSize: 16)),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, String currentLanguage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2740)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          currentLanguage == 'vi' ? 'Báo lỗi' : 'Report a Bug',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          currentLanguage == 'vi'
              ? 'Vui lòng gửi email chi tiết về lỗi đến support@fastnews.com. Chúng tôi sẽ xử lý trong 24 giờ.'
              : 'Please send detailed bug report to support@fastnews.com. We will process within 24 hours.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              currentLanguage == 'vi' ? 'Đóng' : 'Close',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

