import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article_model.dart';

class RssService {
  static final List<String> rssUrls = [
    'https://vnexpress.net/rss/tin-moi-nhat.rss',
    'https://tuoitre.vn/rss/tin-moi-nhat.rss',
    'https://thanhnien.vn/rss/home.rss',
  ];

  static Future<List<ArticleModel>> fetchLatestNews() async {
    List<ArticleModel> allArticles = [];

    for (var url in rssUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          // 🩵 Đảm bảo UTF8
          final utf8Body = utf8.decode(response.bodyBytes);
          final document = XmlDocument.parse(utf8Body);
          final items = document.findAllElements('item');

          for (var item in items.take(8)) {
            final title = item.findElements('title').first.text;
            final link = item.findElements('link').first.text;
            final pubDate = item.findElements('pubDate').isNotEmpty
                ? item.findElements('pubDate').first.text
                : 'Không rõ thời gian';

            // 🧠 Lấy nội dung mô tả hoặc content:encoded
            String description = '';
            if (item.findElements('content:encoded').isNotEmpty) {
              description = item.findElements('content:encoded').first.text;
            } else if (item.findElements('description').isNotEmpty) {
              description = item.findElements('description').first.text;
            }

            // 🧹 Làm sạch HTML & quảng cáo
            description = description
                .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true), '')
                .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '')
                .replaceAll(RegExp(r'<a[^>]*>', caseSensitive: false), '')
                .replaceAll('</a>', '')
                .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                .replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '')
                .replaceAll('&nbsp;', ' ')
                .replaceAll('&amp;', '&')
                .replaceAll('&quot;', '"')
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .trim();

            // 🖼 Tìm ảnh minh họa (nếu có)
            final imageUrl = _extractImageUrl(item.toXmlString());

            allArticles.add(ArticleModel(
              title: title,
              source: _detectSource(url),
              time: pubDate,
              imageUrl: imageUrl,
              link: link,
              description: description,
            ));
          }
        }
      } catch (e) {
        print("❌ Lỗi khi tải RSS từ $url: $e");
      }
    }

    return allArticles;
  }

  static String _extractImageUrl(String text) {
    final regex = RegExp(r'<img.*?src="(.*?)"', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match != null ? match.group(1)! : 'https://picsum.photos/400/250';
  }

  static String _detectSource(String url) {
    if (url.contains('vnexpress')) return 'VNExpress';
    if (url.contains('tuoitre')) return 'Tuổi Trẻ';
    if (url.contains('thanhnien')) return 'Thanh Niên';
    return 'Nguồn khác';
  }
}
