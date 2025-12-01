import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/article_model.dart';
import '../screens/article_detail_screen.dart';
import 'dart:convert';
import '../main.dart';
import 'dart:async';

/// Global notification handler for handling notification taps
class NotificationHandler {
  /// Handle notification tap response
  static void handleNotificationTap(NotificationResponse response) {
    print('');
    print('🔔🔔🔔 ========================================');
    print('🔔 NOTIFICATION TAP DETECTED!');
    print('🔔🔔🔔 ========================================');
    print('🔔 Response ID: ${response.id}');
    print('🔔 Action ID: ${response.actionId}');
    print('🔔 Input: ${response.input}');
    print('🔔 Notification Response Type: ${response.notificationResponseType}');
    print('');

    if (response.payload == null) {
      print('❌❌❌ ERROR: Payload is null!');
      print('');
      return;
    }

    try {
      print('🔔 Payload received: ${response.payload!.substring(0, 50)}...');

      // Parse article from JSON
      final articleData = jsonDecode(response.payload!);
      final article = ArticleModel.fromJson(articleData);
      print('✅ Article parsed: ${article.title}');

      // Navigate to article detail screen with retry logic
      _navigateWithRetry(article);

    } catch (e, stackTrace) {
      print('❌ Error handling notification tap: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Navigate to article detail with retry logic
  static Future<void> _navigateWithRetry(ArticleModel article, {int retryCount = 0}) async {
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
        await _navigateWithRetry(article, retryCount: retryCount + 1);
      } else {
        print('❌ Failed to navigate after $maxRetries attempts');
        print('❌ Navigator state: ${navigatorKey.currentState}');
        print('❌ Navigator context: ${navigatorKey.currentContext}');
      }
    }
  }
}

