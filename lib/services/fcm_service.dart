import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/article_model.dart';

/// Service xử lý Firebase Cloud Messaging (FCM)
/// Nhận push notification từ Firebase Cloud Functions
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM
  Future<void> initialize() async {
    print('🔥 Initializing Firebase Cloud Messaging...');

    // Initialize notification channel for Android
    await _initializeNotificationChannel();

    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 FCM Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted FCM permission');

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('🔑 FCM Token: $_fcmToken');

      // Subscribe to 'all_users' topic để nhận notification từ Cloud Functions
      await subscribeToTopic('all_users');

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
      });

      // Setup message handlers
      _setupMessageHandlers();
    } else {
      print('⚠️ User declined FCM permission');
    }
  }

  /// Initialize notification channel for Android
  Future<void> _initializeNotificationChannel() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    // Create high importance channel for FCM
    const androidChannel = AndroidNotificationChannel(
      'fcm_news_channel',
      'Tin tức từ Cloud',
      description: 'Thông báo tin tức mới từ Firebase Cloud Functions',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

    print('✅ FCM Notification channel created');
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Subscribe to category topics
  Future<void> subscribeToCategories(List<String> categories) async {
    // Unsubscribe from all first
    const allTopics = [
      'all_users',
      'chinh_tri',
      'kinh_te',
      'the_gioi',
      'the_thao',
      'cong_nghe',
      'giai_tri',
      'suc_khoe',
      'du_lich',
    ];

    for (var topic in allTopics) {
      await unsubscribeFromTopic(topic);
    }

    // Subscribe to 'all_users' (always)
    await subscribeToTopic('all_users');

    // Subscribe to selected categories
    for (var category in categories) {
      String topic = _categoryToTopic(category);
      await subscribeToTopic(topic);
    }
  }

  /// Convert category to topic name
  String _categoryToTopic(String category) {
    final Map<String, String> categoryMap = {
      'Tất cả': 'all_users',
      'Chính trị': 'chinh_tri',
      'Kinh tế': 'kinh_te',
      'Thế giới': 'the_gioi',
      'Thể thao': 'the_thao',
      'Công nghệ': 'cong_nghe',
      'Giải trí': 'giai_tri',
      'Sức khỏe': 'suc_khoe',
      'Du lịch': 'du_lich',
    };
    return categoryMap[category] ?? 'all_users';
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // 1. Handle foreground messages (app đang mở)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 2. Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped (background): ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // 3. Check if app was opened from terminated state
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🔔 Notification tapped (terminated): ${message.notification?.title}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'fcm_news_channel',
      'Tin tức từ Cloud',
      channelDescription: 'Thông báo tin tức mới từ Firebase Cloud Functions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF5A7D3C),
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      message.hashCode,
      message.notification?.title ?? '📰 Tin tức mới',
      message.notification?.body ?? 'Có tin tức mới vừa được đăng',
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('🎯 Handling notification tap from FCM');
    print('📦 Data: ${message.data}');

    try {
      // Check if article data exists
      if (message.data.containsKey('article')) {
        final articleJson = message.data['article'];
        print('📰 Article JSON received: ${articleJson?.substring(0, 50)}...');

        // Parse article data
        final articleData = jsonDecode(articleJson!);
        final article = ArticleModel.fromJson(articleData);

        print('✅ Article parsed: ${article.title}');

        // Navigate to article detail using method channel
        // (MainActivity will handle this via Method Channel)
        // Or use navigatorKey if available

        // For now, just log - actual navigation will be handled by MainActivity
        print('🔗 Article link: ${article.link}');
      } else {
        print('⚠️ No article data in FCM message');
      }
    } catch (e, stackTrace) {
      print('❌ Error handling FCM notification tap: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

/// Background message handler (MUST be top-level function)
/// Xử lý message khi app đang tắt hoàn toàn
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔥 [Background] FCM message received: ${message.notification?.title}');
  print('📦 [Background] Data: ${message.data}');

  // Notification sẽ tự động hiển thị bởi Firebase SDK
  // Không cần xử lý gì thêm ở đây
}

