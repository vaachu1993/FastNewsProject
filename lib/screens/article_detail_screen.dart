import 'package:flutter/material.dart';
import '../models/article_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  /// 🔹 Hàm loại bỏ thẻ HTML (giữ lại text thuần)
  String _stripHtmlTags(String htmlText) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlText.replaceAll(exp, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    // Nếu RSS có mô tả HTML, ta lọc ra text
    final plainText = article.description != null
        ? _stripHtmlTags(article.description!)
        : 'Không có nội dung chi tiết cho bài viết này.';

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FastNews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: const [
          Icon(Icons.bookmark_border, color: Colors.black87),
          SizedBox(width: 10),
          Icon(Icons.share_outlined, color: Colors.black87),
          SizedBox(width: 10),
          Icon(Icons.more_vert, color: Colors.black87),
          SizedBox(width: 10),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Ảnh đại diện bài viết
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                article.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // 📰 Tiêu đề
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),

            // 🏷 Nguồn báo
            Text(
              article.source.toUpperCase(),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // 🕒 Thông tin phụ
            Row(
              children: [
                Text(
                  article.time,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.visibility, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('123K', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.favorite_border,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('567', style: TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 20),

            // 📖 Hiển thị nội dung text (đã loại bỏ HTML)
            Text(
              plainText,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 25),

            // 🌐 Nút đọc bài gốc
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(article.link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Đọc bài gốc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
