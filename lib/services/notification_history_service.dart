import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_history_model.dart';

class NotificationHistoryService {
  static final NotificationHistoryService _instance = NotificationHistoryService._internal();
  factory NotificationHistoryService() => _instance;
  NotificationHistoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int _maxHistoryItems = 100; // Giới hạn 100 thông báo

  // Get current user's notification collection
  CollectionReference? _getUserNotificationCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ User not logged in, cannot access notification history');
      return null;
    }
    return _firestore.collection('users').doc(userId).collection('notification_history');
  }

  /// Lưu notification vào lịch sử
  Future<void> saveNotification(NotificationHistoryModel notification) async {
    try {
      final collection = _getUserNotificationCollection();
      if (collection == null) {
        print('⚠️ Cannot save notification - user not logged in');
        return;
      }

      // Lưu vào Firestore với document ID là notification.id
      await collection.doc(notification.id).set({
        ...notification.toJson(),
        'createdAt': FieldValue.serverTimestamp(), // Thêm server timestamp
      });

      print('✅ Saved notification to Firestore: ${notification.title}');

      // Cleanup: Xóa notifications cũ nếu vượt quá giới hạn
      await _cleanupOldNotifications(collection);
    } catch (e) {
      print('❌ Error saving notification to Firestore: $e');
    }
  }

  /// Cleanup old notifications to keep within limit
  Future<void> _cleanupOldNotifications(CollectionReference collection) async {
    try {
      final snapshot = await collection
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.length > _maxHistoryItems) {
        // Xóa các notification cũ
        final docsToDelete = snapshot.docs.skip(_maxHistoryItems);
        for (var doc in docsToDelete) {
          await doc.reference.delete();
        }
        print('🗑️ Cleaned up ${docsToDelete.length} old notifications');
      }
    } catch (e) {
      print('❌ Error cleaning up old notifications: $e');
    }
  }

  /// Lấy danh sách lịch sử thông báo
  Future<List<NotificationHistoryModel>> getNotificationHistory() async {
    try {
      final collection = _getUserNotificationCollection();
      if (collection == null) {
        print('⚠️ Cannot load notification history - user not logged in');
        return [];
      }

      final snapshot = await collection
          .orderBy('timestamp', descending: true)
          .limit(_maxHistoryItems)
          .get();

      final List<NotificationHistoryModel> history = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              return NotificationHistoryModel.fromJson(data);
            } catch (e) {
              print('❌ Error parsing notification: $e');
              return null;
            }
          })
          .whereType<NotificationHistoryModel>()
          .toList();

      print('📋 Loaded ${history.length} notifications from Firestore');
      return history;
    } catch (e) {
      print('❌ Error loading notification history from Firestore: $e');
      return [];
    }
  }

  /// Đánh dấu notification đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      final collection = _getUserNotificationCollection();
      if (collection == null) return;

      await collection.doc(notificationId).update({
        'isRead': true,
      });

      print('✅ Marked notification as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Xóa một notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final collection = _getUserNotificationCollection();
      if (collection == null) return;

      await collection.doc(notificationId).delete();

      print('✅ Deleted notification: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Xóa tất cả notifications
  Future<void> clearAllNotifications() async {
    try {
      final collection = _getUserNotificationCollection();
      if (collection == null) return;

      final snapshot = await collection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Cleared all notification history (${snapshot.docs.length} notifications)');
    } catch (e) {
      print('❌ Error clearing notification history: $e');
    }
  }

  /// Lấy số lượng notifications chưa đọc
  Future<int> getUnreadCount() async {
    try {
      final collection = _getUserNotificationCollection();
      if (collection == null) return 0;

      final snapshot = await collection
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Đánh dấu tất cả là đã đọc
  Future<void> markAllAsRead() async {
    try {
      final collection = _getUserNotificationCollection();
      if (collection == null) return;

      final snapshot = await collection
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      print('✅ Marked all notifications as read (${snapshot.docs.length} notifications)');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }
}

