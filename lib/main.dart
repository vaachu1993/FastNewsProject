import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'models/article_model.dart';
import 'screens/article_detail_screen.dart';
import 'dart:convert';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables từ .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp();

  // ✅ Configure Firestore with offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ✅ Initialize AuthService with persistence
  final authService = AuthService();
  await authService.initializeAuth();

  // ✅ Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // ✅ Setup notification tap handler
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

class FastNewsApp extends StatefulWidget {
  const FastNewsApp({super.key});

  @override
  State<FastNewsApp> createState() => _FastNewsAppState();
}

class _FastNewsAppState extends State<FastNewsApp> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground
        _notificationService.onAppStateChanged(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background or closed
        _notificationService.onAppStateChanged(false);
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        _notificationService.onAppStateChanged(false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Global navigator key
      debugShowCheckedModeBanner: false,
      title: 'FastNews',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
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
  }
}
