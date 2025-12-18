import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article_model.dart';
import '../utils/html_utils.dart';
import '../services/notification_service.dart';
import '../utils/content_deduplication.dart';

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

  // ⚡ CACHE để tránh load lại nhiều lần
  static Map<String, List<ArticleModel>> _cache = {};
  static Map<String, DateTime> _cacheTimestamp = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  static Future<List<ArticleModel>> fetchLatestNews() async {
    List<ArticleModel> allArticles = [];

    // ⚡ LOAD SONG SONG thay vì tuần tự
    final futures = rssUrls.map((url) => _fetchFromUrl(url, itemsLimit: 6));
    final results = await Future.wait(futures);

    for (var articles in results) {
      allArticles.addAll(articles);
    }

    // 🔥 Loại bỏ các bài viết trùng lặp dựa trên nội dung
    print("\n📊 Trước khi lọc trùng lặp: ${allArticles.length} bài viết");

    // Kiểm tra description
    int articlesWithDesc = allArticles.where((a) => a.description != null && a.description!.isNotEmpty).length;
    print("   📝 Số bài có description: $articlesWithDesc/${allArticles.length}");

    allArticles = ContentDeduplication.removeDuplicates(allArticles);
    print("✅ Sau khi loại bỏ trùng lặp: ${allArticles.length} bài viết\n");

    // ✅ Check and notify about new articles
    if (allArticles.isNotEmpty) {
      final notificationService = NotificationService();
      await notificationService.checkAndNotifyNewArticles(allArticles);
    }

    return allArticles;
  }

  // ⚡ Helper method để fetch từ 1 URL với timeout và cache
  static Future<List<ArticleModel>> _fetchFromUrl(String url, {int itemsLimit = 5}) async {
    List<ArticleModel> articles = [];

    try {
      // ⚡ TIMEOUT 5 giây để tránh treo
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("⏱️ Timeout khi tải RSS từ $url");
          return http.Response('', 408); // Request Timeout
        },
      );

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(utf8Body);
        final items = document.findAllElements('item');

        for (var item in items.take(itemsLimit)) {
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

          description = HtmlUtils.decodeHtmlEntities(description);
          final imageUrl = _extractImageUrl(item.toXmlString());

          articles.add(ArticleModel(
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

    return articles;
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

  //Lấy tin tức theo danh mục với CACHE và LOAD SONG SONG
  static Future<List<ArticleModel>> fetchNewsByCategory(String category) async {
    // ⚡ Kiểm tra cache trước
    if (_cache.containsKey(category) && _cacheTimestamp.containsKey(category)) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp[category]!);
      if (cacheAge < _cacheDuration) {
        print("⚡ Sử dụng cache cho category: $category (còn ${_cacheDuration.inMinutes - cacheAge.inMinutes} phút)");
        return _cache[category]!;
      }
    }

    List<ArticleModel> allArticles = [];

    // Nếu chọn "Tất cả", lấy từ tất cả RSS feeds
    if (category == 'Tất cả') {
      return fetchLatestNews();
    }

    //Lọc các RSS feeds theo danh mục
    final filteredFeeds = rssFeeds.where((feed) => feed['category'] == category).toList();

    // ⚡ LOAD SONG SONG thay vì tuần tự - NHANH HỠN RẤT NHIỀU!
    final futures = filteredFeeds.map((feed) => _fetchFromUrl(feed['url']!, itemsLimit: 4));
    final results = await Future.wait(futures);

    for (var articles in results) {
      allArticles.addAll(articles);
    }

    // 🔥 Loại bỏ các bài viết trùng lặp dựa trên nội dung
    print("\n📊 Category '$category' - Trước khi lọc: ${allArticles.length} bài viết");
    int articlesWithDesc = allArticles.where((a) => a.description != null && a.description!.isNotEmpty).length;
    print("   📝 Số bài có description: $articlesWithDesc/${allArticles.length}");

    allArticles = ContentDeduplication.removeDuplicates(allArticles);
    print("✅ Category '$category' sau khi loại bỏ trùng lặp: ${allArticles.length} bài viết\n");

    // ⚡ Lưu vào cache
    _cache[category] = allArticles;
    _cacheTimestamp[category] = DateTime.now();

    return allArticles;
  }

  // Lấy tất cả danh mục có sẵn
  static List<String> getCategories() {
    return ['Tất cả', 'Chính trị', 'Công nghệ', 'Kinh doanh', 'Thể thao', 'Sức khỏe', 'Đời sống'];
  }

  // Tìm kiếm tin tức theo tiêu đề
  /// Tìm kiếm bài viết theo từ khóa
  /// Tìm trong: tiêu đề, mô tả, và nguồn
  /// Hỗ trợ: nhiều từ khóa, tìm kiếm không dấu
  static List<ArticleModel> searchArticles(List<ArticleModel> articles, String query) {
    if (query.trim().isEmpty) return articles;

    // Tách query thành các từ khóa riêng lẻ và normalize
    final keywords = query.trim().toLowerCase().split(RegExp(r'\s+'));

    return articles.where((article) {
      // Chuẩn bị text để tìm kiếm (title + description + source)
      final titleLower = article.title.toLowerCase();
      final descLower = (article.description ?? '').toLowerCase();
      final sourceLower = article.source.toLowerCase();

      // Kết hợp tất cả nội dung để tìm kiếm
      final searchableText = '$titleLower $descLower $sourceLower';

      // Normalize Vietnamese (bỏ dấu) cho tìm kiếm linh hoạt hơn
      final normalizedText = _removeVietnameseTones(searchableText);

      // Kiểm tra xem TẤT CẢ các từ khóa có xuất hiện không
      return keywords.every((keyword) {
        final normalizedKeyword = _removeVietnameseTones(keyword);
        return searchableText.contains(keyword) ||
               normalizedText.contains(normalizedKeyword);
      });
    }).toList();
  }

  /// Bỏ dấu tiếng Việt để hỗ trợ tìm kiếm linh hoạt
  /// Ví dụ: "Việt Nam" -> "viet nam"
  static String _removeVietnameseTones(String text) {
    const vietnameseMap = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };

    String result = text;
    vietnameseMap.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }

  // 📊 Thống kê và phân tích bài viết trùng lặp
  static Map<String, dynamic> analyzeArticleDuplicates(List<ArticleModel> articles) {
    if (articles.isEmpty) {
      return {'total': 0, 'unique': 0, 'duplicates': 0, 'groups': []};
    }

    final groups = ContentDeduplication.groupSimilarArticles(articles);
    final duplicateGroups = groups.where((group) => group.length > 1).toList();

    int totalDuplicates = 0;
    for (var group in duplicateGroups) {
      totalDuplicates += (group.length - 1); // Trừ đi 1 bài gốc
    }

    return {
      'total': articles.length,
      'unique': groups.length,
      'duplicates': totalDuplicates,
      'duplicateGroups': duplicateGroups.length,
      'groups': duplicateGroups.map((group) {
        return {
          'count': group.length,
          'titles': group.map((a) => '${a.source}: ${a.title}').toList(),
        };
      }).toList(),
    };
  }

  // Lấy tin tức ngẫu nhiên hoặc mới nhất - TỐI ƯU
  static Future<List<ArticleModel>> fetchRandomNews() async {
    // ⚡ LOAD SONG SONG tất cả RSS feeds
    final futures = rssUrls.map((url) => _fetchFromUrl(url, itemsLimit: 5));
    final results = await Future.wait(futures);

    List<ArticleModel> allArticles = [];
    for (var articles in results) {
      allArticles.addAll(articles);
    }

    // 🔥 Loại bỏ các bài viết trùng lặp dựa trên nội dung
    print("\n📊 Random News - Trước khi lọc: ${allArticles.length} bài viết");
    int articlesWithDesc = allArticles.where((a) => a.description != null && a.description!.isNotEmpty).length;
    print("   📝 Số bài có description: $articlesWithDesc/${allArticles.length}");

    allArticles = ContentDeduplication.removeDuplicates(allArticles);
    print("✅ Random News sau khi loại bỏ trùng lặp: ${allArticles.length} bài viết\n");

    // Shuffle lại toàn bộ danh sách
    allArticles.shuffle(Random());
    return allArticles;
  }
}
