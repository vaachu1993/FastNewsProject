import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Network connectivity check
  Future<bool> _hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('❌ Network check failed: $e');
      return false;
    }
  }

  // Enhanced error handler for Firestore operations
  Future<T?> _executeWithErrorHandling<T>(
    String operationName,
    Future<T> Function() operation, {
    T? fallbackValue,
    bool useOfflineCache = true,
  }) async {
    try {
      // Check network connectivity first
      final hasNetwork = await _hasNetworkConnection();

      if (!hasNetwork) {
        print('⚠️ No network connection for $operationName');
        if (useOfflineCache) {
          return await _getFromOfflineCache<T>(operationName);
        }
        return fallbackValue;
      }

      // Execute the operation
      final result = await operation();

      // Cache successful results
      if (useOfflineCache && result != null) {
        await _saveToOfflineCache(operationName, result);
      }

      return result;
    } on FirebaseException catch (e) {
      print('🔥 Firebase error in $operationName: ${e.code} - ${e.message}');
      return await _handleFirebaseError(e, operationName, fallbackValue);
    } on SocketException catch (e) {
      print('🌐 Network error in $operationName: $e');
      return useOfflineCache
          ? await _getFromOfflineCache<T>(operationName) ?? fallbackValue
          : fallbackValue;
    } catch (e) {
      print('❌ General error in $operationName: $e');
      return fallbackValue;
    }
  }

  // Handle specific Firebase errors
  Future<T?> _handleFirebaseError<T>(
    FirebaseException e,
    String operationName,
    T? fallbackValue
  ) async {
    switch (e.code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'resource-exhausted':
        print('⏰ Firestore temporarily unavailable, using cache');
        return await _getFromOfflineCache<T>(operationName) ?? fallbackValue;

      case 'permission-denied':
        print('🔒 Permission denied for $operationName');
        return fallbackValue;

      case 'unauthenticated':
        print('👤 User not authenticated for $operationName');
        return fallbackValue;

      default:
        print('🔥 Unhandled Firebase error: ${e.code}');
        return fallbackValue;
    }
  }

  // Offline cache management
  Future<T?> _getFromOfflineCache<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cache_$key');
      if (cachedData != null) {
        print('📱 Retrieved from offline cache: $key');
        // For simple cases, return the cached string
        // For complex objects, you'd need to implement proper JSON deserialization
        return cachedData as T?;
      }
    } catch (e) {
      print('❌ Cache retrieval error: $e');
    }
    return null;
  }

  Future<void> _saveToOfflineCache<T>(String key, T data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Simple string cache - for complex objects, implement JSON serialization
      await prefs.setString('cache_$key', data.toString());
    } catch (e) {
      print('❌ Cache save error: $e');
    }
  }

  // Tạo document ID hợp lệ từ link
  String _getDocumentId(String link) {
    // Sử dụng MD5 hash để tạo ID ngắn gọn và hợp lệ
    var bytes = utf8.encode(link);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  // Add bookmark
  Future<bool> addBookmark(ArticleModel article) async {
    return await _executeWithErrorHandling<bool>(
      'addBookmark',
      () async {
        if (currentUserId == null) {
          print('Error: User not logged in');
          return false;
        }

        final docId = _getDocumentId(article.link);
        print('Adding bookmark with ID: $docId for user: $currentUserId');

        // Lưu article vào subcollection bookmarks
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('bookmarks')
            .doc(docId)
            .set({
          'title': article.title,
          'link': article.link,
          'description': article.description ?? '',
          'pubDate': article.time,
          'imageUrl': article.imageUrl,
          'source': article.source,
          'bookmarkedAt': FieldValue.serverTimestamp(),
        });

        print('Bookmark added successfully');
        return true;
      },
      fallbackValue: false,
      useOfflineCache: false, // Don't cache bookmark operations
    ) ?? false;
  }

  // Remove bookmark
  Future<bool> removeBookmark(String articleLink) async {
    try {
      if (currentUserId == null) {
        print('Error: User not logged in');
        return false;
      }

      final docId = _getDocumentId(articleLink);
      print('Removing bookmark with ID: $docId for user: $currentUserId');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('bookmarks')
          .doc(docId)
          .delete();

      print('Bookmark removed successfully');
      return true;
    } catch (e) {
      print('Error removing bookmark: $e');
      return false;
    }
  }

  // Check if article is bookmarked
  Future<bool> isBookmarked(String articleLink) async {
    return await _executeWithErrorHandling<bool>(
      'isBookmarked_${_getDocumentId(articleLink)}',
      () async {
        if (currentUserId == null) {
          print('Error: User not logged in');
          return false;
        }

        final docId = _getDocumentId(articleLink);
        print('Checking bookmark with ID: $docId for user: $currentUserId');

        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('bookmarks')
            .doc(docId)
            .get();

        final exists = doc.exists;
        print('Bookmark exists: $exists');
        return exists;
      },
      fallbackValue: false,
      useOfflineCache: true,
    ) ?? false;
  }

  // Get all bookmarks as stream
  Stream<List<ArticleModel>> getBookmarksStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('bookmarks')
          .snapshots()
          .map((snapshot) {
        // Sort by bookmarkedAt locally instead of using Firestore orderBy
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aTime = a.data()['bookmarkedAt'] as Timestamp?;
          final bTime = b.data()['bookmarkedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending order
        });

        return docs.map((doc) {
          final data = doc.data();
          return ArticleModel(
            title: data['title'] ?? '',
            link: data['link'] ?? '',
            description: data['description'] ?? '',
            time: data['pubDate'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            source: data['source'] ?? '',
          );
        }).toList();
      });
    } catch (e) {
      print('Error getting bookmarks stream: $e');
      return Stream.value([]);
    }
  }

  // Get all bookmarks (one-time fetch)
  Future<List<ArticleModel>> getBookmarks() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('bookmarks')
          .get();

      // Sort by bookmarkedAt locally
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTime = aData['bookmarkedAt'] as Timestamp?;
        final bTime = bData['bookmarkedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // Descending order
      });

      return docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ArticleModel(
          title: data['title'] ?? '',
          link: data['link'] ?? '',
          description: data['description'] ?? '',
          time: data['pubDate'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          source: data['source'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error getting bookmarks: $e');
      return [];
    }
  }

  // Toggle bookmark (add if not exists, remove if exists)
  Future<bool> toggleBookmark(ArticleModel article) async {
    bool isCurrentlyBookmarked = await isBookmarked(article.link);

    if (isCurrentlyBookmarked) {
      return await removeBookmark(article.link);
    } else {
      return await addBookmark(article);
    }
  }

  // Get user's favorite topics
  Future<List<String>> getUserFavoriteTopics() async {
    try {
      if (currentUserId == null) {
        print('Error: User not logged in');
        return [];
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!doc.exists) {
        print('User document does not exist');
        return [];
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        print('No user data found');
        return [];
      }

      // Check for selectedTopics first (from registration), then fallback to favoriteTopics
      List<dynamic>? topics;
      if (data.containsKey('selectedTopics')) {
        topics = data['selectedTopics'] as List<dynamic>?;
      } else if (data.containsKey('favoriteTopics')) {
        topics = data['favoriteTopics'] as List<dynamic>?;
      }

      if (topics == null || topics.isEmpty) {
        print('No favorite topics found in selectedTopics or favoriteTopics');
        return [];
      }

      return topics.map((e) => e.toString()).toList();
    } catch (e) {
      print('Error getting user favorite topics: $e');
      return [];
    }
  }

  // Save user's favorite topics
  Future<bool> saveUserFavoriteTopics(List<String> topics) async {
    try {
      if (currentUserId == null) {
        print('Error: User not logged in');
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'selectedTopics': topics, // Primary field (from registration)
        'favoriteTopics': topics, // Keep for backward compatibility
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Favorite topics saved successfully');
      return true;
    } catch (e) {
      print('Error saving favorite topics: $e');
      return false;
    }
  }

  // ==================== READING HISTORY ====================

  // Add article to reading history
  Future<bool> addToReadingHistory(ArticleModel article) async {
    try {
      if (currentUserId == null) {
        print('Error: User not logged in');
        return false;
      }

      final docId = _getDocumentId(article.link);
      print('Adding to reading history with ID: $docId for user: $currentUserId');

      // Lưu article vào subcollection reading_history
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('reading_history')
          .doc(docId)
          .set({
        'title': article.title,
        'link': article.link,
        'description': article.description ?? '',
        'pubDate': article.time,
        'imageUrl': article.imageUrl,
        'source': article.source,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true để cập nhật readAt nếu đã tồn tại

      print('Added to reading history successfully');
      return true;
    } catch (e) {
      print('Error adding to reading history: $e');
      return false;
    }
  }

  // Get reading history as stream
  Stream<List<ArticleModel>> getReadingHistoryStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('reading_history')
          .snapshots()
          .map((snapshot) {
        // Sort by readAt locally
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aTime = a.data()['readAt'] as Timestamp?;
          final bTime = b.data()['readAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending order (newest first)
        });

        return docs.map((doc) {
          final data = doc.data();
          return ArticleModel(
            title: data['title'] ?? '',
            link: data['link'] ?? '',
            description: data['description'] ?? '',
            time: data['pubDate'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            source: data['source'] ?? '',
          );
        }).toList();
      });
    } catch (e) {
      print('Error getting reading history stream: $e');
      return Stream.value([]);
    }
  }

  // Get reading history (one-time fetch)
  Future<List<ArticleModel>> getReadingHistory({int limit = 20}) async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('reading_history')
          .get();

      // Sort by readAt locally
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTime = aData['readAt'] as Timestamp?;
        final bTime = bData['readAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // Descending order (newest first)
      });

      // Apply limit
      final limitedDocs = docs.take(limit);

      return limitedDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ArticleModel(
          title: data['title'] ?? '',
          link: data['link'] ?? '',
          description: data['description'] ?? '',
          time: data['pubDate'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          source: data['source'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error getting reading history: $e');
      return [];
    }
  }

  // Clear reading history
  Future<bool> clearReadingHistory() async {
    try {
      if (currentUserId == null) {
        print('Error: User not logged in');
        return false;
      }

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('reading_history')
          .get();

      // Delete all documents in batch
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('Reading history cleared successfully');
      return true;
    } catch (e) {
      print('Error clearing reading history: $e');
      return false;
    }
  }
}

