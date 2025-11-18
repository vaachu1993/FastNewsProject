import 'dart:convert';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article_model.dart';
import '../utils/html_utils.dart';
import '../services/notification_service.dart';

class RssService {
  static final List<String> rssUrls = [
    'https://vnexpress.net/rss/tin-moi-nhat.rss',
    'https://tuoitre.vn/rss/tin-moi-nhat.rss',
    'https://thanhnien.vn/rss/home.rss',
  ];

  static final List<Map<String, String>> rssFeeds = [
    // Thể thao
    {'url': 'https://vnexpress.net/rss/the-thao.rss', 'category': 'Thể thao'},
    {'url': 'https://tuoitre.vn/rss/the-thao.rss', 'category': 'Thể thao'},
    {'url': 'https://thanhnien.vn/rss/the-thao.rss', 'category': 'Thể thao'},

    // Công nghệ
    {'url': 'https://vnexpress.net/rss/so-hoa.rss', 'category': 'Công nghệ'},
    {'url': 'https://tuoitre.vn/rss/nhip-song-so.rss', 'category': 'Công nghệ'},
    {'url': 'https://thanhnien.vn/rss/cong-nghe.rss', 'category': 'Công nghệ'},

    // Kinh doanh
    {'url': 'https://vnexpress.net/rss/kinh-doanh.rss', 'category': 'Kinh doanh'},
    {'url': 'https://tuoitre.vn/rss/kinh-doanh.rss', 'category': 'Kinh doanh'},
    {'url': 'https://thanhnien.vn/rss/kinh-te.rss', 'category': 'Kinh doanh'},

    // Sức khỏe
    {'url': 'https://vnexpress.net/rss/suc-khoe.rss', 'category': 'Sức khỏe'},
    {'url': 'https://tuoitre.vn/rss/suc-khoe.rss', 'category': 'Sức khỏe'},
    {'url': 'https://thanhnien.vn/rss/suc-khoe.rss', 'category': 'Sức khỏe'},

    // Chính trị
    {'url': 'https://vnexpress.net/rss/thoi-su.rss', 'category': 'Chính trị'},
    {'url': 'https://tuoitre.vn/rss/thoi-su.rss', 'category': 'Chính trị'},
    {'url': 'https://thanhnien.vn/rss/thoi-su.rss', 'category': 'Chính trị'},

    // Đời sống
    {'url': 'https://vnexpress.net/rss/gia-dinh.rss', 'category': 'Đời sống'},
    {'url': 'https://tuoitre.vn/rss/van-hoa.rss', 'category': 'Đời sống'},
    {'url': 'https://thanhnien.vn/rss/doi-song.rss', 'category': 'Đời sống'},
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
            final rawTitle = item.findElements('title').first.innerText;
            final title = HtmlUtils.decodeHtmlEntities(rawTitle);
            final link = item.findElements('link').first.innerText;
            final pubDate = item.findElements('pubDate').isNotEmpty
                ? item.findElements('pubDate').first.innerText
                : 'Không rõ thời gian';

            // Lấy nội dung mô tả hoặc content:encoded
            String description = '';
            if (item.findElements('content:encoded').isNotEmpty) {
              description = item.findElements('content:encoded').first.innerText;
            } else if (item.findElements('description').isNotEmpty) {
              description = item.findElements('description').first.innerText;
            }

            // Làm sạch HTML & quảng cáo
            description = description
                .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true), '')
                .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '')
                .replaceAll(RegExp(r'<a[^>]*>', caseSensitive: false), '')
                .replaceAll('</a>', '')
                .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                .replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '')
                .trim();

            // Decode HTML entities
            description = HtmlUtils.decodeHtmlEntities(description);

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
        print("Lỗi khi tải RSS từ $url: $e");
      }
    }

    // ✅ Check and notify about new articles
    if (allArticles.isNotEmpty) {
      final notificationService = NotificationService();
      await notificationService.checkAndNotifyNewArticles(allArticles);
    }

    return allArticles;
  }

  static String _extractImageUrl(String text) {
    final regex = RegExp(r'<img.*?src="(.*?)"', caseSensitive: false);
    final match = regex.firstMatch(text);
    // Return empty string if no image found - will show placeholder widget instead
    return match != null ? match.group(1)! : '';
  }

  static String _detectSource(String url) {
    if (url.contains('vnexpress')) return 'VNExpress';
    if (url.contains('tuoitre')) return 'Tuổi Trẻ';
    if (url.contains('thanhnien')) return 'Thanh Niên';
    return 'Nguồn khác';
  }

  //Lấy tin tức theo danh mục
  static Future<List<ArticleModel>> fetchNewsByCategory(String category) async {
    List<ArticleModel> allArticles = [];

    // Nếu chọn "Tất cả", lấy từ tất cả RSS feeds
    if (category == 'Tất cả') {
      return fetchLatestNews();
    }

    //Lọc các RSS feeds theo danh mục
    final filteredFeeds = rssFeeds.where((feed) => feed['category'] == category).toList();

    for (var feed in filteredFeeds) {
      try {
        final response = await http.get(Uri.parse(feed['url']!));
        if (response.statusCode == 200) {
          final utf8Body = utf8.decode(response.bodyBytes);
          final document = XmlDocument.parse(utf8Body);
          final items = document.findAllElements('item');

          for (var item in items.take(5)) {
            final rawTitle = item.findElements('title').first.innerText;
            final title = HtmlUtils.decodeHtmlEntities(rawTitle);

            final link = item.findElements('link').first.innerText;
            final pubDate = item.findElements('pubDate').isNotEmpty
                ? item.findElements('pubDate').first.innerText
                : 'Không rõ thời gian';

            String description = '';
            if (item.findElements('content:encoded').isNotEmpty) {
              description = item.findElements('content:encoded').first.innerText;
            } else if (item.findElements('description').isNotEmpty) {
              description = item.findElements('description').first.innerText;
            }

            description = description
                .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true), '')
                .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '')
                .replaceAll(RegExp(r'<a[^>]*>', caseSensitive: false), '')
                .replaceAll('</a>', '')
                .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                .replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '')
                .trim();

            // Decode HTML entities
            description = HtmlUtils.decodeHtmlEntities(description);

            final imageUrl = _extractImageUrl(item.toXmlString());

            allArticles.add(ArticleModel(
              title: title,
              source: _detectSource(feed['url']!),
              time: pubDate,
              imageUrl: imageUrl,
              link: link,
              description: description,
            ));
          }
        }
      } catch (e) {
        print("Lỗi khi tải RSS từ ${feed['url']}: $e");
      }
    }

    return allArticles;
  }

  // Lấy tất cả danh mục có sẵn
  static List<String> getCategories() {
    return ['Tất cả', 'Chính trị', 'Công nghệ', 'Kinh doanh', 'Thể thao', 'Sức khỏe', 'Đời sống'];
  }

  // Tìm kiếm tin tức theo tiêu đề
  static List<ArticleModel> searchArticles(List<ArticleModel> articles, String query) {
    if (query.isEmpty) return articles;

    final lowerQuery = query.toLowerCase();
    return articles.where((article) {
      return article.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Lấy tin tức ngẫu nhiên hoặc mới nhất
  static Future<List<ArticleModel>> fetchRandomNews() async {
    List<ArticleModel> allArticles = [];

    // Lấy từ tất cả các RSS feeds
    final allFeeds = [...rssUrls];

    // Random thứ tự các feeds
    allFeeds.shuffle(Random());

    for (var url in allFeeds.take(3)) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final utf8Body = utf8.decode(response.bodyBytes);
          final document = XmlDocument.parse(utf8Body);
          final items = document.findAllElements('item').toList();

          // Shuffle các items để random
          items.shuffle(Random());

          for (var item in items.take(8)) {
            final rawTitle = item.findElements('title').first.innerText;
            final title = HtmlUtils.decodeHtmlEntities(rawTitle);
            final link = item.findElements('link').first.innerText;
            final pubDate = item.findElements('pubDate').isNotEmpty
                ? item.findElements('pubDate').first.innerText
                : 'Không rõ thời gian';

            String description = '';
            if (item.findElements('content:encoded').isNotEmpty) {
              description = item.findElements('content:encoded').first.innerText;
            } else if (item.findElements('description').isNotEmpty) {
              description = item.findElements('description').first.innerText;
            }

            description = description
                .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true), '')
                .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '')
                .replaceAll(RegExp(r'<a[^>]*>', caseSensitive: false), '')
                .replaceAll('</a>', '')
                .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                .replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '')
                .trim();

            // Decode HTML entities
            description = HtmlUtils.decodeHtmlEntities(description);

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
        print("Lỗi khi tải RSS từ $url: $e");
      }
    }

    // Shuffle lại toàn bộ danh sách
    allArticles.shuffle(Random());
    return allArticles;
  }
}
