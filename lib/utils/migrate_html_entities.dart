import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/html_utils.dart';

/// Utility to migrate existing Firestore data and decode HTML entities
class MigrateHtmlEntities {
  static final _firestore = FirebaseFirestore.instance;

  /// Migrate bookmarks for current user
  static Future<void> migrateBookmarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_articles')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String?;
        final description = data['description'] as String?;

        if (title != null) {
          final decodedTitle = HtmlUtils.decodeHtmlEntities(title);
          final decodedDescription = description != null
              ? HtmlUtils.decodeHtmlEntities(description)
              : null;

          await doc.reference.update({
            'title': decodedTitle,
            if (description != null) 'description': decodedDescription,
          });
        }
      }

      print('✅ Migrated ${snapshot.docs.length} bookmarks');
    } catch (e) {
      print('❌ Error migrating bookmarks: $e');
    }
  }

  /// Migrate reading history for current user
  static Future<void> migrateReadingHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reading_history')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String?;
        final description = data['description'] as String?;

        if (title != null) {
          final decodedTitle = HtmlUtils.decodeHtmlEntities(title);
          final decodedDescription = description != null
              ? HtmlUtils.decodeHtmlEntities(description)
              : null;

          await doc.reference.update({
            'title': decodedTitle,
            if (description != null) 'description': decodedDescription,
          });
        }
      }

      print('✅ Migrated ${snapshot.docs.length} reading history items');
    } catch (e) {
      print('❌ Error migrating reading history: $e');
    }
  }

  /// Migrate all data for current user
  static Future<void> migrateAll() async {
    print('🔄 Starting migration...');
    await migrateBookmarks();
    await migrateReadingHistory();
    print('✅ Migration complete!');
  }
}

