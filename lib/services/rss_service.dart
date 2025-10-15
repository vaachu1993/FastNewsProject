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
          final document = XmlDocument.parse(response.body);
          final items = document.findAllElements('item');

          for (var item in items.take(8)) { // lấy 8 bài đầu mỗi nguồn
            final title = item.findElements('title').first.text;
            final link = item.findElements('link').first.text;
            final pubDate = item.findElements('pubDate').isNotEmpty
                ? item.findElements('pubDate').first.text
                : 'Không rõ thời gian';
            final description = item.findElements('description').isNotEmpty
                ? item.findElements('description').first.text
                : '';
            final imageUrl = _extractImageUrl(description);

            allArticles.add(ArticleModel(
              title: title,
              source: _detectSource(url),
              time: pubDate,
              imageUrl: imageUrl,
              link: link,
            ));
          }
        }
      } catch (e) {
        print("❌ Lỗi khi tải RSS từ $url: $e");
      }
    }

    return allArticles;
  }

  static String _extractImageUrl(String description) {
    final regex = RegExp(r'<img.*?src="(.*?)"', caseSensitive: false);
    final match = regex.firstMatch(description);
    return match != null ? match.group(1)! : 'https://picsum.photos/400/250';
  }

  static String _detectSource(String url) {
    if (url.contains('vnexpress')) return 'VNExpress';
    if (url.contains('tuoitre')) return 'Tuổi Trẻ';
    if (url.contains('thanhnien')) return 'Thanh Niên';
    return 'Nguồn khác';
  }
}
