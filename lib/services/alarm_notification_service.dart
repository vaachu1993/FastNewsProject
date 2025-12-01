import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert';
import 'dart:ui';
import '../models/article_model.dart';
import 'notification_handler.dart';

/// Service sử dụng Android Alarm Manager Plus để chạy background task
/// ngay cả khi app đã tắt hoàn toàn
class AlarmNotificationService {
  static const String isolatePortName = 'alarm_notification_port';
  static const int alarmId = 0;
  static const String lastCheckKey = 'last_news_check_time';
  static const String notifiedArticlesKey = 'notified_articles';

  // RSS feed URLs
  static const Map<String, String> rssFeeds = {
    'Tất cả': 'https://vnexpress.net/rss/tin-moi-nhat.rss',
    'Chính trị': 'https://vnexpress.net/rss/thoi-su.rss',
    'Kinh tế': 'https://vnexpress.net/rss/kinh-doanh.rss',
    'Thế giới': 'https://vnexpress.net/rss/the-gioi.rss',
    'Thể thao': 'https://vnexpress.net/rss/the-thao.rss',
    'Công nghệ': 'https://vnexpress.net/rss/so-hoa.rss',
    'Giải trí': 'https://vnexpress.net/rss/giai-tri.rss',
    'Sức khỏe': 'https://vnexpress.net/rss/suc-khoe.rss',
    'Du lịch': 'https://vnexpress.net/rss/du-lich.rss',
  };

  /// Initialize Android Alarm Manager
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    print('🔔 Android Alarm Manager initialized');
  }

  /// Start periodic background news checking
  /// Chạy mỗi 15 phút ngay cả khi app đã tắt
  static Future<void> startPeriodicNewsCheck() async {
    try {
      // Cancel existing alarms first
      await AndroidAlarmManager.cancel(alarmId);

      // Schedule periodic alarm - chạy mỗi 15 phút
      final success = await AndroidAlarmManager.periodic(
        const Duration(minutes: 15),
        alarmId,
        backgroundNewsCheckCallback,
        exact: true,
        wakeup: true, // Đánh thức thiết bị nếu đang ngủ
        rescheduleOnReboot: true, // Tự động schedule lại sau khi reboot
        allowWhileIdle: true, // Cho phép chạy khi thiết bị idle
      );

      if (success) {
        print('✅ Periodic news check scheduled successfully (every 15 minutes)');
        print('⏰ Will run even when app is closed');
        print('🔋 Will wake device if needed');
      } else {
        print('❌ Failed to schedule periodic news check');
      }
    } catch (e) {
      print('❌ Error starting periodic news check: $e');
    }
  }

  /// Schedule one-time immediate check
  static Future<void> scheduleImmediateCheck() async {
    try {
      final success = await AndroidAlarmManager.oneShot(
        const Duration(seconds: 10),
        alarmId + 1,
        backgroundNewsCheckCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
      );

      if (success) {
        print('✅ Immediate news check scheduled (in 10 seconds)');
      }
    } catch (e) {
      print('❌ Error scheduling immediate check: $e');
    }
  }

  /// Stop periodic background news checking
  static Future<void> stopPeriodicNewsCheck() async {
    try {
      await AndroidAlarmManager.cancel(alarmId);
      await AndroidAlarmManager.cancel(alarmId + 1);
      print('🛑 Periodic news check stopped');
    } catch (e) {
      print('❌ Error stopping periodic news check: $e');
    }
  }

  /// Background callback - MUST be a top-level or static function
  /// Đây là function sẽ được gọi bởi AlarmManager
  @pragma('vm:entry-point')
  static Future<void> backgroundNewsCheckCallback() async {
    print('🔍 [AlarmManager] Background news check started');
    print('📅 Time: ${DateTime.now()}');

    try {
      // Check if notifications are enabled
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true; // Default TRUE

      print('🔔 Notification status: $notificationsEnabled');

      if (!notificationsEnabled) {
        print('🔕 Notifications disabled, skipping check');
        return;
      }

      print('✅ Notifications enabled, proceeding with news check');

      // Get selected topics
      final selectedTopicsJson = prefs.getString('selectedTopics');
      List<String> selectedTopics = [];

      if (selectedTopicsJson != null && selectedTopicsJson.isNotEmpty) {
        try {
          selectedTopics = List<String>.from(jsonDecode(selectedTopicsJson));
        } catch (e) {
          selectedTopics = ['Tất cả'];
        }
      } else {
        selectedTopics = ['Tất cả'];
      }

      print('📋 Checking topics: ${selectedTopics.join(", ")}');

      // Fetch news from selected topics
      List<ArticleModel> allArticles = [];

      for (String topic in selectedTopics) {
        final feedUrl = rssFeeds[topic];
        if (feedUrl != null) {
          final articles = await _fetchArticlesFromRss(feedUrl, topic);
          allArticles.addAll(articles);
        }
      }

      if (allArticles.isEmpty) {
        print('📭 No new articles found');
        return;
      }

      // Get notified articles
      final notifiedArticles = prefs.getStringList(notifiedArticlesKey) ?? [];

      // Find new articles
      final newArticles = allArticles.where((article) {
        return !notifiedArticles.contains(article.link);
      }).toList();

      if (newArticles.isEmpty) {
        print('📭 No new articles to notify');
        return;
      }

      // Notify about new articles (limit to 3 most recent)
      final articlesToNotify = newArticles.take(3).toList();

      for (var article in articlesToNotify) {
        await _showNotification(article);
        notifiedArticles.add(article.link);
      }

      // Save notified articles (keep only last 100)
      if (notifiedArticles.length > 100) {
        notifiedArticles.removeRange(0, notifiedArticles.length - 100);
      }
      await prefs.setStringList(notifiedArticlesKey, notifiedArticles);

      // Update last check time
      await prefs.setString(lastCheckKey, DateTime.now().toIso8601String());

      print('✅ Notified about ${articlesToNotify.length} new articles');
      print('📊 Total articles found: ${allArticles.length}');

    } catch (e, stackTrace) {
      print('❌ Error in background news check: $e');
      print('📚 Stack trace: $stackTrace');
    }
  }

  /// Fetch articles from RSS feed
  static Future<List<ArticleModel>> _fetchArticlesFromRss(String url, String source) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        List<ArticleModel> articles = [];

        for (var item in items.take(10)) { // Limit to 10 articles per feed
          try {
            final title = item.findElements('title').first.innerText;
            final link = item.findElements('link').first.innerText;
            final description = item.findElements('description').firstOrNull?.innerText ?? '';
            final pubDate = item.findElements('pubDate').firstOrNull?.innerText ?? '';

            // Extract image URL
            String imageUrl = '';
            final descriptionElement = item.findElements('description').firstOrNull;
            if (descriptionElement != null) {
              final descText = descriptionElement.innerText;
              final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(descText);
              if (imgMatch != null) {
                imageUrl = imgMatch.group(1) ?? '';
              }
            }

            articles.add(ArticleModel(
              title: title,
              link: link,
              description: _cleanHtmlTags(description),
              time: pubDate,
              source: source,
              imageUrl: imageUrl,
            ));
          } catch (e) {
            // Skip invalid items
            continue;
          }
        }

        return articles;
      }
    } catch (e) {
      print('❌ Error fetching RSS from $url: $e');
    }

    return [];
  }

  /// Clean HTML tags from text
  static String _cleanHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Show notification
  static Future<void> _showNotification(ArticleModel article) async {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

    // Initialize with callback handler
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // Initialize với NotificationHandler để handle notification tap globally
    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: NotificationHandler.handleNotificationTap,
    );

    // Create notification channel - Đồng nhất với NotificationService
    const androidChannel = AndroidNotificationChannel(
      'news_channel',
      'Tin tức mới',
      description: 'Thông báo về tin tức mới nhất',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

    // Show notification
    final androidDetails = AndroidNotificationDetails(
      'news_channel',
      'Tin tức mới',
      channelDescription: 'Thông báo về tin tức mới nhất',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF5A7D3C),
    );

    final details = NotificationDetails(android: androidDetails);

    await notifications.show(
      article.link.hashCode, // Unique ID based on article link
      '📰 ${article.source}',
      article.title,
      details,
      payload: jsonEncode(article.toJson()),
    );

    print('📬 Notification sent: ${article.title}');
  }

  /// Get last check time
  static Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(lastCheckKey);

    if (timeString != null) {
      return DateTime.parse(timeString);
    }

    return null;
  }

  /// Test alarm (for debugging)
  static Future<void> testAlarm() async {
    print('🧪 Testing alarm...');

    final success = await AndroidAlarmManager.oneShot(
      const Duration(seconds: 5),
      999,
      testCallback,
      exact: true,
      wakeup: true,
    );

    if (success) {
      print('✅ Test alarm scheduled (will fire in 5 seconds)');
    } else {
      print('❌ Failed to schedule test alarm');
    }
  }

  @pragma('vm:entry-point')
  static void testCallback() {
    print('🎉 Test alarm fired successfully!');
    print('📅 Time: ${DateTime.now()}');
  }
}

