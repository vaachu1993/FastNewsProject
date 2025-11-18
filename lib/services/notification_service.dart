import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'rss_service.dart';
import 'background_news_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Callback for handling notification taps
  static void Function(String articleJson)? onNotificationTap;

  // Background task constants
  static const String _isolatePortName = 'notification_isolate_port';

  // Timer for periodic checks
  Timer? _periodicTimer;

  // Background isolate
  static ReceivePort? _receivePort;

  // Initialize notification service
  Future<void> initialize() async {
    // Initialize AdvancedNotificationService instead of Workmanager
    final advancedService = AdvancedNotificationService();
    await advancedService.initialize();

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

    // Request permissions for Android 13+
    await _requestPermissions();

    // Initialize background processing
    await _initializeBackgroundProcessing();

    print('🔔 Notification service initialized with AdvancedNotificationService');
  }

  // Initialize background processing
  Future<void> _initializeBackgroundProcessing() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (notificationsEnabled) {
      await startBackgroundNewsCheck();
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && onNotificationTap != null) {
      onNotificationTap!(response.payload!);
    }
  }

  // Show notification for new article
  Future<void> showNewArticleNotification(ArticleModel article) async {
    const androidDetails = AndroidNotificationDetails(
      'news_channel',
      'Tin tức mới',
      channelDescription: 'Thông báo về tin tức mới nhất',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF5A7D3C),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert article to JSON for payload
    final articleJson = jsonEncode(article.toJson());

    await _notifications.show(
      article.id.hashCode, // Use article ID as notification ID
      '📰 ${article.source}',
      article.title,
      details,
      payload: articleJson,
    );
  }

  // Check and notify about new articles
  Future<void> checkAndNotifyNewArticles(List<ArticleModel> newArticles) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if notifications are enabled
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    if (!notificationsEnabled) {
      print('🔕 Notifications are disabled');
      return;
    }

    // Get last seen article ID
    final lastSeenArticleId = prefs.getString('last_seen_article_id');

    if (lastSeenArticleId == null || newArticles.isEmpty) {
      // First time or no articles - just save the latest
      if (newArticles.isNotEmpty) {
        await prefs.setString('last_seen_article_id', newArticles.first.id);
      }
      return;
    }

    // Find new articles (articles that appear before the last seen one)
    final newUnseenArticles = <ArticleModel>[];
    for (var article in newArticles) {
      if (article.id == lastSeenArticleId) {
        break; // Stop when we reach the last seen article
      }
      newUnseenArticles.add(article);
    }

    // Notify about new articles (limit to 3 notifications at once)
    final articlesToNotify = newUnseenArticles.take(3).toList();
    for (var article in articlesToNotify) {
      await showNewArticleNotification(article);
      // Add small delay between notifications
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Update last seen article
    if (newArticles.isNotEmpty) {
      await prefs.setString('last_seen_article_id', newArticles.first.id);
      print('✅ Notified about ${articlesToNotify.length} new articles');
    }
  }

  // Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      await startBackgroundNewsCheck();
    } else {
      await stopBackgroundNewsCheck();
    }

    print('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  // Start background news checking
  Future<void> startBackgroundNewsCheck() async {
    // Cancel existing timer
    _periodicTimer?.cancel();

    // Use AdvancedNotificationService for enhanced background checking
    final advancedService = AdvancedNotificationService();
    await advancedService.startBackgroundNewsCheck();

    print('🚀 Background news checking started with AdvancedNotificationService');
    print('📋 Multiple strategies: Timers + Scheduled notifications');
    print('⏰ Enhanced coverage for app-closed scenarios');
  }

  // Stop background news checking
  Future<void> stopBackgroundNewsCheck() async {
    _periodicTimer?.cancel();
    _periodicTimer = null;

    // Stop AdvancedNotificationService
    final advancedService = AdvancedNotificationService();
    await advancedService.stopBackgroundNewsCheck();

    print('🛑 Background news checking stopped (AdvancedNotificationService stopped)');
  }

  // Background news check method
  Future<void> _checkNewsInBackground() async {
    try {
      print('📡 Checking news in background...');

      // Fetch latest news
      final latestNews = await RssService.fetchLatestNews();

      if (latestNews.isNotEmpty) {
        // Check and notify about new articles
        await checkAndNotifyNewArticles(latestNews);
      }

      // Schedule next scheduled notification check
      await _scheduleNextCheck();

    } catch (e) {
      print('❌ Error checking news in background: $e');
    }
  }

  // Schedule next notification check (for when app is completely closed)
  Future<void> _scheduleNextCheck() async {
    // Since schedule method may not be available, we'll use a Timer approach
    Timer(const Duration(minutes: 30), () async {
      await _checkNewsInBackground();
    });
  }

  // Handle app lifecycle changes
  Future<void> onAppStateChanged(bool isAppInForeground) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!notificationsEnabled) return;

    if (isAppInForeground) {
      // App is in foreground - check for new articles immediately
      print('📱 App in foreground - checking news...');
      await _checkNewsInBackground();
    } else {
      // App goes to background - schedule more frequent checks
      print('🔄 App in background - scheduling background checks...');
      await _scheduleBackgroundChecks();
    }
  }

  // Schedule multiple background checks when app is closed
  Future<void> _scheduleBackgroundChecks() async {
    // Schedule checks at different intervals using Timers instead of scheduled notifications
    final checkIntervals = [5, 15, 30, 60]; // minutes

    for (int i = 0; i < checkIntervals.length; i++) {
      final minutes = checkIntervals[i];

      Timer(Duration(minutes: minutes), () async {
        await _checkNewsInBackground();
      });
    }
  }

  // Static method for background isolate
  @pragma('vm:entry-point')
  static void backgroundIsolateEntryPoint() {
    WidgetsFlutterBinding.ensureInitialized();

    final port = IsolateNameServer.lookupPortByName(_isolatePortName);

    if (port != null) {
      port.send('background_task_started');

      // Perform background news check
      Timer.periodic(const Duration(minutes: 15), (timer) async {
        try {
          final latestNews = await RssService.fetchLatestNews();

          if (latestNews.isNotEmpty) {
            // Send data back to main isolate
            port.send({
              'type': 'new_articles',
              'data': latestNews.map((e) => e.toJson()).toList(),
            });
          }
        } catch (e) {
          port.send({
            'type': 'error',
            'message': e.toString(),
          });
        }
      });
    }
  }

  // Get notification status
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Test notification
  Future<void> sendTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'news_channel',
      'Tin tức mới',
      channelDescription: 'Thông báo về tin tức mới nhất',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF5A7D3C),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999999,
      '📰 FastNews',
      'Thông báo tin tức đang hoạt động!',
      details,
    );
  }

  // Test notification system with mock data
  Future<void> testNotificationSystem() async {
    print('🧪 Testing notification system...');

    // Create mock article for testing
    final mockArticle = ArticleModel(
      title: 'Test notification - Tin tức thử nghiệm',
      source: 'FastNews Test',
      time: DateTime.now().toString(),
      imageUrl: 'https://via.placeholder.com/300x200',
      link: 'https://example.com',
      description: 'Đây là tin tức thử nghiệm để kiểm tra hệ thống thông báo.',
    );

    // Show test notification
    await showNewArticleNotification(mockArticle);
    print('✅ Test notification sent!');

    // Log current notification settings
    final enabled = await areNotificationsEnabled();
    print('📱 Notifications enabled: $enabled');

    if (enabled) {
      print('🚀 Background checking is active');
      print('⏰ Next check in 30 minutes');
    } else {
      print('🔕 Notifications are disabled');
    }
  }

  // Dispose resources
  void dispose() {
    _periodicTimer?.cancel();
    _receivePort?.close();
  }
}
