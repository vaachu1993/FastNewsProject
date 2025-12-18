import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/localization_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          loc.termsAndConditions,
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
            // Introduction
            Text(
              currentLanguage == 'vi'
                ? 'Chào mừng đến với FastNews'
                : 'Welcome to FastNews',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              currentLanguage == 'vi'
                ? 'Vui lòng đọc kỹ các điều khoản và điều kiện sau đây trước khi sử dụng ứng dụng của chúng tôi.'
                : 'Please read these terms and conditions carefully before using our application.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Section 1
            _buildSection(
              context,
              currentLanguage == 'vi' ? '1. Chấp nhận điều khoản' : '1. Acceptance of Terms',
              currentLanguage == 'vi'
                ? 'Bằng việc truy cập và sử dụng ứng dụng FastNews, bạn đồng ý tuân thủ và bị ràng buộc bởi các điều khoản và điều kiện sau đây. Nếu bạn không đồng ý với bất kỳ phần nào của các điều khoản này, vui lòng không sử dụng ứng dụng.'
                : 'By accessing and using the FastNews application, you agree to be bound by these terms and conditions. If you do not agree with any part of these terms, please do not use the application.',
            ),

            // Section 2
            _buildSection(
              context,
              currentLanguage == 'vi' ? '2. Sử dụng dịch vụ' : '2. Use of Service',
              currentLanguage == 'vi'
                ? 'FastNews cung cấp dịch vụ đọc tin tức từ nhiều nguồn khác nhau. Bạn có trách nhiệm:\n\n• Sử dụng ứng dụng một cách hợp pháp và phù hợp\n• Không sử dụng ứng dụng cho mục đích bất hợp pháp\n• Không can thiệp vào hoạt động của ứng dụng\n• Không vi phạm quyền sở hữu trí tuệ của người khác'
                : 'FastNews provides news reading services from various sources. You are responsible for:\n\n• Using the application legally and appropriately\n• Not using the application for illegal purposes\n• Not interfering with the operation of the application\n• Not violating intellectual property rights',
            ),

            // Section 3
            _buildSection(
              context,
              currentLanguage == 'vi' ? '3. Tài khoản người dùng' : '3. User Account',
              currentLanguage == 'vi'
                ? 'Khi tạo tài khoản, bạn đồng ý:\n\n• Cung cấp thông tin chính xác và đầy đủ\n• Duy trì tính bảo mật của tài khoản\n• Chịu trách nhiệm cho tất cả hoạt động dưới tài khoản của bạn\n• Thông báo ngay cho chúng tôi về bất kỳ vi phạm bảo mật nào'
                : 'When creating an account, you agree to:\n\n• Provide accurate and complete information\n• Maintain account security\n• Be responsible for all activities under your account\n• Notify us immediately of any security breach',
            ),

            // Section 4
            _buildSection(
              context,
              currentLanguage == 'vi' ? '4. Nội dung' : '4. Content',
              currentLanguage == 'vi'
                ? 'Tất cả nội dung tin tức được cung cấp từ các nguồn bên thứ ba. FastNews không chịu trách nhiệm về:\n\n• Độ chính xác của nội dung\n• Tính kịp thời của thông tin\n• Bất kỳ thiệt hại nào phát sinh từ việc sử dụng nội dung\n\nBạn có quyền đọc, lưu và chia sẻ nội dung theo đúng quy định pháp luật.'
                : 'All news content is provided from third-party sources. FastNews is not responsible for:\n\n• Content accuracy\n• Information timeliness\n• Any damages arising from content use\n\nYou have the right to read, save and share content in accordance with the law.',
            ),

            // Section 5
            _buildSection(
              context,
              currentLanguage == 'vi' ? '5. Quyền riêng tư' : '5. Privacy',
              currentLanguage == 'vi'
                ? 'Chúng tôi cam kết bảo vệ quyền riêng tư của bạn. Việc thu thập và sử dụng thông tin cá nhân được quy định trong Chính sách Bảo mật của chúng tôi. Bằng việc sử dụng ứng dụng, bạn đồng ý với việc thu thập và xử lý thông tin như được mô tả trong chính sách đó.'
                : 'We are committed to protecting your privacy. The collection and use of personal information is governed by our Privacy Policy. By using the application, you consent to the collection and processing of information as described in that policy.',
            ),

            // Section 6
            _buildSection(
              context,
              currentLanguage == 'vi' ? '6. Thay đổi điều khoản' : '6. Changes to Terms',
              currentLanguage == 'vi'
                ? 'Chúng tôi có quyền thay đổi các điều khoản này bất cứ lúc nào. Các thay đổi sẽ có hiệu lực ngay khi được đăng tải. Việc bạn tiếp tục sử dụng ứng dụng sau khi có thay đổi đồng nghĩa với việc bạn chấp nhận các điều khoản mới.'
                : 'We reserve the right to change these terms at any time. Changes will be effective immediately upon posting. Your continued use of the application after changes constitutes acceptance of the new terms.',
            ),

            // Section 7
            _buildSection(
              context,
              currentLanguage == 'vi' ? '7. Giới hạn trách nhiệm' : '7. Limitation of Liability',
              currentLanguage == 'vi'
                ? 'FastNews sẽ không chịu trách nhiệm cho bất kỳ thiệt hại trực tiếp, gián tiếp, ngẫu nhiên, đặc biệt hoặc hệ quả nào phát sinh từ:\n\n• Việc sử dụng hoặc không thể sử dụng ứng dụng\n• Truy cập trái phép vào dữ liệu của bạn\n• Lỗi hoặc thiếu sót trong nội dung\n• Bất kỳ vấn đề nào khác liên quan đến ứng dụng'
                : 'FastNews will not be liable for any direct, indirect, incidental, special or consequential damages arising from:\n\n• Use or inability to use the application\n• Unauthorized access to your data\n• Errors or omissions in content\n• Any other issues related to the application',
            ),

            // Section 8
            _buildSection(
              context,
              currentLanguage == 'vi' ? '8. Liên hệ' : '8. Contact',
              currentLanguage == 'vi'
                ? 'Nếu bạn có bất kỳ câu hỏi nào về các điều khoản này, vui lòng liên hệ với chúng tôi qua:\n\nEmail: support@fastnews.com\nĐịa chỉ: Việt Nam'
                : 'If you have any questions about these terms, please contact us at:\n\nEmail: support@fastnews.com\nAddress: Vietnam',
            ),

            const SizedBox(height: 24),

            // Last updated
            Center(
              child: Text(
                currentLanguage == 'vi'
                  ? 'Cập nhật lần cuối: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
                  : 'Last updated: ${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

