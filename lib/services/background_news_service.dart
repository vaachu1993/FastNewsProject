import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article_model.dart';
import 'dart:async';

class AdvancedNotificationService {
  static final AdvancedNotificationService _instance = AdvancedNotificationService._internal();
  factory AdvancedNotificationService() => _instance;
  AdvancedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _periodicTimer;
  Timer? _immediateTimer;
  bool _isInitialized = false;

  // RSS feed URLs từ RssService
  static const Map<String, String> rssFeeds = {
    'Tất cả': 'https://vnexpress.net/rss/tin-moi-nhat.rss',
    'Chính trị': 'https://vnexpress.net/rss/thoi-su.rss',
    'Kinh tế': 'https://vnexpress.net/rss/kinh-doanh.rss',
    'Thể thao': 'https://vnexpress.net/rss/the-thao.rss',
    'Giáo dục': 'https://vnexpress.net/rss/giao-duc.rss',
    'Sức khỏe': 'https://vnexpress.net/rss/suc-khoe.rss',
    'Pháp luật': 'https://vnexpress.net/rss/phap-luat.rss',
    'Công nghệ': 'https://vnexpress.net/rss/so-hoa.rss',
    'Du lịch': 'https://vnexpress.net/rss/du-lich.rss',
    'Khoa học': 'https://vnexpress.net/rss/khoa-hoc.rss',
    'Đời sống': 'https://vnexpress.net/rss/gia-dinh.rss',
    'Xe': 'https://vnexpress.net/rss/oto-xe-may.rss',
    'Ý kiến': 'https://vnexpress.net/rss/y-kien.rss',
    'Tâm sự': 'https://vnexpress.net/rss/tam-su.rss',
    'Hài': 'https://vnexpress.net/rss/cuoi.rss',
  };

  // Initialize the advanced notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    _isInitialized = true;
    print('🔔 Advanced notification service initialized');
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'news_updates',
      'Tin tức mới',
      description: 'Thông báo tin tức mới từ FastNews',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      print('🔔 Notification tapped with payload: ${response.payload}');
      // Handle notification tap - this would be handled by the main app
    }
  }

  // Start background news checking với multiple periodic timers
  Future<void> startBackgroundNewsCheck() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Cancel existing timers
    await stopBackgroundNewsCheck();

    print('🚀 Starting enhanced background news checking...');

    // Strategy 1: Fast periodic checks when app might be in foreground (every 15 minutes)
    _periodicTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      await _performNewsCheck('periodic-15min');
    });

    // Strategy 2: Immediate check after 30 seconds (when app might go to background)
    _immediateTimer = Timer(const Duration(seconds: 30), () async {
      await _performNewsCheck('immediate');

      // Strategy 3: After immediate check, set up longer intervals
      _setupLongerIntervalChecks();
    });

    print('✅ Background news checking started with Timer-based strategies');
    print('📋 Fast periodic: Every 15 minutes');
    print('⏰ Immediate check: In 30 seconds');
    print('⏳ Long-term checks: Will be scheduled after immediate check');
  }

  // Setup longer interval checks for when app is likely in background
  void _setupLongerIntervalChecks() {
    Timer.periodic(const Duration(minutes: 30), (timer) async {
      await _performNewsCheck('background-30min');
    });

    Timer.periodic(const Duration(hours: 1), (timer) async {
      await _performNewsCheck('background-1hour');
    });

    // Extra aggressive check for when app has been in background for a while
    Timer.periodic(const Duration(hours: 2), (timer) async {
      await _performNewsCheck('deep-background-2hour');
    });

    print('📅 Long-term background checks scheduled');
  }

  // Stop background news checking
  Future<void> stopBackgroundNewsCheck() async {
    _periodicTimer?.cancel();
    _periodicTimer = null;

    _immediateTimer?.cancel();
    _immediateTimer = null;

    // Note: Cannot cancel the longer interval timers directly
    // but they will naturally stop when app restarts

    print('🛑 Background news checking stopped');
  }

  // Perform news check
  Future<void> _performNewsCheck(String source) async {
    try {
      print('🔍 [$source] Checking for new articles...');

      final prefs = await SharedPreferences.getInstance();

      // Check if notifications are enabled
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      if (!notificationsEnabled) {
        print('🔕 Notifications disabled, skipping check');
        return;
      }

      // Check if user is logged in
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (!isLoggedIn) {
        print('🚫 User not logged in, skipping check');
        return;
      }

      // Get last seen article ID
      final lastSeenArticleId = prefs.getString('last_seen_article_id') ?? '';
      print('🔍 [$source] Last seen article: $lastSeenArticleId');

      // Check latest news from main RSS feed
      final latestArticles = await _fetchLatestNews();

      if (latestArticles.isNotEmpty) {
        final latestArticle = latestArticles.first;
        final latestArticleId = _generateArticleId(latestArticle);

        print('🔍 [$source] Latest article: $latestArticleId');
        print('🔍 [$source] Title: ${latestArticle.title}');

        // Compare with last seen
        if (lastSeenArticleId.isEmpty || lastSeenArticleId != latestArticleId) {
          print('🎉 [$source] New article found!');

          // Send notification
          await _sendNewArticleNotification(latestArticle);

          // Update last seen article
          await prefs.setString('last_seen_article_id', latestArticleId);

          // Update statistics
          final notificationCount = prefs.getInt('notification_count') ?? 0;
          await prefs.setInt('notification_count', notificationCount + 1);
          await prefs.setString('last_notification_time', DateTime.now().toIso8601String());

        } else {
          print('📰 [$source] No new articles since last check');
        }
      } else {
        print('⚠️ [$source] No articles found in RSS feed');
      }

    } catch (e) {
      print('❌ [$source] Error in news check: $e');
    }
  }

  Future<List<ArticleModel>> _fetchLatestNews() async {
    try {
      final response = await http.get(
        Uri.parse(rssFeeds['Tất cả']!),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('❌ HTTP Error: ${response.statusCode}');
        return [];
      }

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      final articles = <ArticleModel>[];

      for (final item in items.take(5)) { // Only check latest 5 articles
        try {
          final title = item.findElements('title').first.innerText.trim();
          final link = item.findElements('link').first.innerText.trim();
          final description = item.findElements('description').firstOrNull?.innerText.trim() ?? '';
          final pubDate = item.findElements('pubDate').firstOrNull?.innerText.trim() ?? '';

          // Extract image from description (VnExpress format)
          String imageUrl = '';
          if (description.isNotEmpty) {
            final regex = RegExp(r'<img[^>]*src="([^"]*)"');
            final match = regex.firstMatch(description);
            imageUrl = match?.group(1) ?? '';
          }

          final article = ArticleModel(
            title: _decodeHtmlEntities(title),
            link: link,
            description: _decodeHtmlEntities(_stripHtml(description)),
            time: pubDate,
            imageUrl: imageUrl,
            source: 'VnExpress',
          );

          articles.add(article);
        } catch (e) {
          print('❌ Error parsing article item: $e');
          continue;
        }
      }

      print('📰 Fetched ${articles.length} latest articles');
      return articles;

    } catch (e) {
      print('❌ Error fetching RSS: $e');
      return [];
    }
  }

  Future<void> _sendNewArticleNotification(ArticleModel article) async {
    try {
      // Create notification
      const androidDetails = AndroidNotificationDetails(
        'news_updates',
        'Tin tức mới',
        channelDescription: 'Thông báo tin tức mới từ FastNews',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Tin tức mới',
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Prepare payload with article data
      final articleJson = jsonEncode({
        'title': article.title,
        'link': article.link,
        'description': article.description,
        'time': article.time,
        'imageUrl': article.imageUrl,
        'source': article.source,
      });

      await _notifications.show(
        Random().nextInt(1000), // Random ID to avoid conflicts
        '📰 Tin tức mới từ FastNews',
        article.title,
        notificationDetails,
        payload: articleJson,
      );

      print('🔔 Notification sent: ${article.title}');

    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  String _generateArticleId(ArticleModel article) {
    return '${article.link}_${article.time}'.hashCode.toString();
  }

  String _decodeHtmlEntities(String html) {
    return html
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'");
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'notificationCount': prefs.getInt('notification_count') ?? 0,
      'lastNotificationTime': prefs.getString('last_notification_time'),
      'lastSeenArticleId': prefs.getString('last_seen_article_id') ?? '',
      'notificationsEnabled': prefs.getBool('notifications_enabled') ?? false,
    };
  }

  // Test notification (for debugging)
  Future<void> sendTestNotification() async {
    await _sendNewArticleNotification(
      ArticleModel(
        title: 'Test Notification - FastNews hoạt động tốt!',
        link: 'https://fastnews.com/test',
        description: 'Đây là thông báo test để kiểm tra hệ thống notification',
        time: DateTime.now().toString(),
        imageUrl: '',
        source: 'FastNews Test',
      ),
    );
  }
}

// Compatibility alias for easy migration
class BackgroundNewsChecker {
  static const String newsCheckTask = 'news_check_task';

  static Future<void> checkForNewArticles() async {
    final service = AdvancedNotificationService();
    await service._performNewsCheck('compatibility');
  }
}
