import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Helper class để xử lý kết nối Firestore với retry logic
class FirestoreConnectionHelper {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Kiểm tra xem Firestore có kết nối được không
  static Future<bool> checkConnection() async {
    try {
      // Thử query đơn giản để test connection
      await FirebaseFirestore.instance
          .collection('test')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));

      debugPrint('✅ Firestore connection OK');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore connection failed: $e');
      return false;
    }
  }

  /// Thực hiện một Firestore query với retry logic
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = maxRetries,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxAttempts) {
          debugPrint('❌ Max retry attempts reached: $e');
          rethrow;
        }

        debugPrint('⚠️ Attempt $attempts failed, retrying in ${retryDelay.inSeconds}s...');
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Failed after $maxAttempts attempts');
  }

  /// Lấy document với retry và offline fallback
  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentWithRetry({
    required String collection,
    required String docId,
  }) async {
    return executeWithRetry(
      operation: () async {
        try {
          // Thử lấy từ server trước
          return await FirebaseFirestore.instance
              .collection(collection)
              .doc(docId)
              .get(const GetOptions(source: Source.server));
        } catch (e) {
          // Nếu server fail, lấy từ cache
          debugPrint('⚠️ Server unavailable, using cache');
          return await FirebaseFirestore.instance
              .collection(collection)
              .doc(docId)
              .get(const GetOptions(source: Source.cache));
        }
      },
    );
  }

  /// Set document với retry
  static Future<void> setDocumentWithRetry({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    return executeWithRetry(
      operation: () => FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: merge)),
    );
  }

  /// Update document với retry
  static Future<void> updateDocumentWithRetry({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    return executeWithRetry(
      operation: () => FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .update(data),
    );
  }

  /// Query collection với retry và offline fallback
  static Future<QuerySnapshot<Map<String, dynamic>>> queryCollectionWithRetry({
    required String collection,
    Query<Map<String, dynamic>>? Function(CollectionReference<Map<String, dynamic>>)? queryBuilder,
  }) async {
    return executeWithRetry(
      operation: () async {
        try {
          final collectionRef = FirebaseFirestore.instance.collection(collection);
          final query = queryBuilder?.call(collectionRef) ?? collectionRef;

          // Thử lấy từ server trước
          return await query.get(const GetOptions(source: Source.server));
        } catch (e) {
          // Nếu server fail, lấy từ cache
          debugPrint('⚠️ Server unavailable, using cache');
          final collectionRef = FirebaseFirestore.instance.collection(collection);
          final query = queryBuilder?.call(collectionRef) ?? collectionRef;

          return await query.get(const GetOptions(source: Source.cache));
        }
      },
    );
  }
}

