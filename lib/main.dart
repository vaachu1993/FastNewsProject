import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'widgets/localization_provider.dart';
import 'providers/theme_provider.dart';
import 'models/article_model.dart';
import 'screens/article_detail_screen.dart';
import 'dart:convert';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Method channel for notification handling from native side
const platform = MethodChannel('com.example.fastnews/notification');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup method channel handler for notifications from MainActivity
  platform.setMethodCallHandler((call) async {
    print('📱📱📱 Method channel call received: ${call.method}');

    if (call.method == 'onNotificationTapped') {
      final String payload = call.arguments as String;
      print('🔔🔔🔔 NOTIFICATION TAPPED VIA METHOD CHANNEL!');
      final previewLength = payload.length > 50 ? 50 : payload.length;
      print('📦 Payload: ${payload.substring(0, previewLength)}...');

      try {
        final articleData = jsonDecode(payload);
        final article = ArticleModel.fromJson(articleData);
        print('✅ Article parsed: ${article.title}');

        // Navigate with retry
        _navigateToArticle(article);
      } catch (e, stackTrace) {
        print('❌ Error parsing notification: $e');
        print('Stack trace: $stackTrace');
      }
    }
  });

  // Load environment variables từ .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp();

  // Configure Firestore with offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize AuthService with persistence
  final authService = AuthService();
  await authService.initializeAuth();

  // Initialize Localization Service
  final localizationService = LocalizationService();
  await localizationService.initialize();

  // Initialize Android Alarm Manager for background notifications
  await AndroidAlarmManager.initialize();
  print('🔔 Android Alarm Manager initialized in main');

  // Initialize Firebase Cloud Messaging Background Handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize FCM Service
  final fcmService = FCMService();
  await fcmService.initialize();
  print('🔥 Firebase Cloud Messaging initialized');

  // Setup notification tap handler
  NotificationService.onNotificationTap = (String articleJson) {
    try {
      final articleData = jsonDecode(articleJson);
      final article = ArticleModel.fromJson(articleData);

      // Navigate to article detail screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ArticleDetailScreen(article: article),
        ),
      );
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  };

  runApp(const FastNewsApp());
}

// Navigate to article with retry logic
void _navigateToArticle(ArticleModel article, {int retryCount = 0}) async {
  const maxRetries = 10;
  const retryDelay = Duration(milliseconds: 500);

  print('🔄 Navigation attempt ${retryCount + 1}/$maxRetries');

  if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
    try {
      await navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => ArticleDetailScreen(article: article),
        ),
      );
      print('✅ Successfully navigated to article detail screen');
      print('📰 Article: ${article.title}');
    } catch (e) {
      print('❌ Navigation error: $e');
    }
  } else {
    if (retryCount < maxRetries) {
      print('⏳ Navigator not ready, waiting... (attempt ${retryCount + 1}/$maxRetries)');
      await Future.delayed(retryDelay);
      _navigateToArticle(article, retryCount: retryCount + 1);
    } else {
      print('❌ Failed to navigate after $maxRetries attempts');
    }
  }
}

class FastNewsApp extends StatefulWidget {
  const FastNewsApp({super.key});

  @override
  State<FastNewsApp> createState() => _FastNewsAppState();
}

class _FastNewsAppState extends State<FastNewsApp> {
  final LocalizationService _localizationService = LocalizationService();


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: LocalizationProvider(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              navigatorKey: navigatorKey, // Global navigator key
              debugShowCheckedModeBanner: false,
              title: 'FastNews',
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              locale: _localizationService.currentLocale,
              supportedLocales: LocalizationService.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
        home: FutureBuilder<Map<String, dynamic>>(
          future: AuthService().getLoginState(),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Check login state
            final loginState = snapshot.data;
            final isLoggedIn = loginState?['isLoggedIn'] ?? false;

            if (isLoggedIn) {
              // User is logged in - navigate to main app with bottom navigation
              return const MainScreen();
            } else {
              // User is not logged in - show login screen
              return const LoginScreen();
            }
          },
        ),
            );
          },
        ),
      ),
    );
  }
}
