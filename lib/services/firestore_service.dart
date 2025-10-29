import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Tạo document ID hợp lệ từ link
  String _getDocumentId(String link) {
    // Sử dụng MD5 hash để tạo ID ngắn gọn và hợp lệ
    var bytes = utf8.encode(link);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  // Add bookmark
  Future<bool> addBookmark(ArticleModel article) async {
    try {
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
    } catch (e) {
      print('Error adding bookmark: $e');
      return false;
    }
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
    try {
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
    } catch (e) {
      print('Error checking bookmark: $e');
      return false;
    }
  }

  // Get all bookmarks as stream
  Stream<List<ArticleModel>> getBookmarksStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('bookmarks')
        .orderBy('bookmarkedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
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
  }

  // Get all bookmarks (one-time fetch)
  Future<List<ArticleModel>> getBookmarks() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('bookmarks')
          .orderBy('bookmarkedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
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
}

