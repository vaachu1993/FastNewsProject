import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'alarm_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Callback for handling notification taps
  static void Function(String articleJson)? onNotificationTap;

  // Timer for periodic checks (cleanup only)
  Timer? _periodicTimer;

  // Initialize notification service
  Future<void> initialize() async {
    // Initialize AlarmNotificationService for true background operation
    await AlarmNotificationService.initialize();

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

    print('🔔 Notification service initialized with AlarmNotificationService');
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      print('🔔 Android notification permission granted: $granted');

      // Also request exact alarm permission for background tasks
      final exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
      print('⏰ Exact alarm permission granted: $exactAlarmGranted');
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('🔔 iOS notification permission granted: $granted');
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
      icon: '@mipmap/logo_app',
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

    // Use AlarmNotificationService for TRUE background operation
    // This works even when app is completely closed
    await AlarmNotificationService.startPeriodicNewsCheck();

    print('🚀 Background news checking started with AlarmManager');
    print('⏰ Will check every 15 minutes even when app is closed');
    print('🔋 Device will wake up if needed');
    print('✅ No backup needed - AlarmManager handles all scenarios');
  }

  // Stop background news checking
  Future<void> stopBackgroundNewsCheck() async {
    _periodicTimer?.cancel();
    _periodicTimer = null;

    // Stop AlarmNotificationService
    await AlarmNotificationService.stopPeriodicNewsCheck();

    print('🛑 Background news checking stopped (AlarmManager service stopped)');
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

  // Test notification with a sample article
  Future<void> testNotification() async {
    print('');
    print('🧪🧪🧪 ========================================');
    print('🧪 TEST NOTIFICATION STARTED');
    print('🧪🧪🧪 ========================================');
    print('');

    // Check pending notifications first
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    print('📋 Current pending notifications: ${pendingNotifications.length}');

    // Check active notifications
    final activeNotifications = await _notifications.getActiveNotifications();
    print('📋 Current active notifications: ${activeNotifications.length}');
    print('');

    // Create a test article with proper parameters
    final testArticle = ArticleModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: '🧪 Thông báo Test - Tap vào để xem chi tiết',
      description: 'Đây là thông báo thử nghiệm. Nếu bạn thấy màn hình chi tiết bài viết sau khi tap vào thông báo này, tức là chức năng đã hoạt động tốt! ✅',
      link: 'https://example.com/test-article',
      imageUrl: 'https://via.placeholder.com/400x250.png?text=Test+Article',
      time: DateTime.now().toString(),
      source: 'FastNews Test',
    );

    print('📋 Test article created:');
    print('   - ID: ${testArticle.id}');
    print('   - Title: ${testArticle.title}');
    print('   - Link: ${testArticle.link}');
    print('');

    try {
      await showNewArticleNotification(testArticle);

      // Wait a bit then check again
      await Future.delayed(const Duration(milliseconds: 500));
      final afterNotifications = await _notifications.getActiveNotifications();
      print('📋 Active notifications after sending: ${afterNotifications.length}');

      print('');
      print('✅✅✅ Test notification sent successfully!');
      print('📱 Swipe down to check your notification tray');
      print('👆 TAP on the notification');
      print('🔔 You should see logs starting with "🔔🔔🔔"');
      print('');
    } catch (e, stackTrace) {
      print('❌ Error sending test notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Dispose resources
  void dispose() {
    _periodicTimer?.cancel();
  }
}
