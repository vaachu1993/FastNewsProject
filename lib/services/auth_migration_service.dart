// ignore_for_file: avoid_print, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================
/// MIGRATION SCRIPT: Multi-Provider → Single-Provider
/// ============================================
///
/// Script này được sử dụng để migrate existing users
/// từ multi-provider sang single-provider policy
///
/// Chạy script này MỘT LẦN sau khi deploy code mới
/// hoặc để code tự động fix khi user login lần tiếp theo
///

class AuthMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ============================================
  /// OPTION 1: Automatic Migration (Recommended)
  /// ============================================
  ///
  /// Code đã có logic tự động fix khi user login:
  /// - _ensureSingleProvider() được gọi mỗi lần đăng nhập
  /// - Tự động clean up providers array
  ///
  /// Không cần chạy migration script, chỉ cần deploy code
  /// và để users tự nhiên login để được migrate
  ///
  /// Pros:
  /// - Không cần chạy script riêng
  /// - Không risk data loss
  /// - Gradual migration
  ///
  /// Cons:
  /// - Users phải login lại để được migrate
  /// - Có thể có inconsistency cho đến khi user login
  ///

  /// ============================================
  /// OPTION 2: Batch Migration Script
  /// ============================================
  ///
  /// Chạy script này để migrate TẤT CẢ users cùng lúc
  ///
  /// ⚠️ CẢNH BÁO: Test kỹ trước khi chạy trên production!
  ///
  Future<MigrationResult> migrateAllUsersToSingleProvider({
    bool dryRun = true, // Set false để actually run migration
  }) async {
    print('🔵 Starting migration to single-provider...');
    print('Mode: ${dryRun ? "DRY RUN (no changes)" : "LIVE (will modify data)"}');

    final result = MigrationResult();

    try {
      // Get all users from Firestore
      final usersSnapshot = await _firestore.collection('users').get();
      result.totalUsers = usersSnapshot.docs.length;

      print('📊 Found ${result.totalUsers} users to check');

      for (var doc in usersSnapshot.docs) {
        final uid = doc.id;
        final data = doc.data();

        // Check if user needs migration
        final migrationNeeded = await _checkIfMigrationNeeded(uid, data);

        if (migrationNeeded != null) {
          result.usersNeedingMigration++;

          print('\n🔍 User $uid needs migration:');
          print('   Current: ${migrationNeeded.currentProviders}');
          print('   Should be: ${migrationNeeded.correctProvider}');
          print('   Reason: ${migrationNeeded.reason}');

          if (!dryRun) {
            // Actually perform migration
            await _migrateUser(uid, migrationNeeded);
            result.migratedUsers++;
            print('   ✅ Migrated');
          } else {
            print('   ⏭️  Skipped (dry run)');
          }
        } else {
          result.usersAlreadyCorrect++;
        }
      }

      print('\n' + '=' * 50);
      print('📊 Migration Summary:');
      print('   Total users: ${result.totalUsers}');
      print('   Already correct: ${result.usersAlreadyCorrect}');
      print('   Need migration: ${result.usersNeedingMigration}');
      print('   Migrated: ${result.migratedUsers}');
      print('   Failed: ${result.failedMigrations}');
      print('=' * 50);

      result.success = true;

    } catch (e) {
      print('🔴 Migration error: $e');
      result.success = false;
      result.errorMessage = e.toString();
    }

    return result;
  }

  /// Check if user needs migration
  Future<MigrationInfo?> _checkIfMigrationNeeded(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final providers = List<String>.from(data['providers'] ?? []);
    final loginMethod = data['loginMethod'] as String?;

    // Case 1: Multiple providers (needs migration)
    if (providers.length > 1) {
      // Determine correct provider based on loginMethod
      String correctProvider = _determineCorrectProvider(loginMethod, providers);

      return MigrationInfo(
        uid: uid,
        currentProviders: providers,
        correctProvider: correctProvider,
        reason: 'Multiple providers detected',
      );
    }

    // Case 2: Single provider but wrong value
    if (providers.length == 1) {
      final provider = providers[0];

      // Check if provider matches loginMethod
      if (loginMethod == 'google' && provider != 'google.com') {
        return MigrationInfo(
          uid: uid,
          currentProviders: providers,
          correctProvider: 'google.com',
          reason: 'Provider does not match loginMethod',
        );
      }

      if (loginMethod == 'email' && provider != 'password') {
        return MigrationInfo(
          uid: uid,
          currentProviders: providers,
          correctProvider: 'password',
          reason: 'Provider does not match loginMethod',
        );
      }
    }

    // Case 3: No providers array (very old users)
    if (providers.isEmpty) {
      String correctProvider = _determineCorrectProvider(loginMethod, []);

      return MigrationInfo(
        uid: uid,
        currentProviders: [],
        correctProvider: correctProvider,
        reason: 'No providers array found',
      );
    }

    return null; // No migration needed
  }

  /// Determine correct provider based on loginMethod and existing providers
  String _determineCorrectProvider(String? loginMethod, List<String> providers) {
    // Priority 1: Use loginMethod if available
    if (loginMethod == 'google') {
      return 'google.com';
    }
    if (loginMethod == 'email') {
      return 'password';
    }

    // Priority 2: Use most recent provider (prefer google over password)
    if (providers.contains('google.com')) {
      return 'google.com';
    }
    if (providers.contains('password')) {
      return 'password';
    }

    // Default: assume password
    return 'password';
  }

  /// Perform migration for a single user
  Future<void> _migrateUser(String uid, MigrationInfo info) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'providers': [info.correctProvider],
        'migratedAt': FieldValue.serverTimestamp(),
        'migrationReason': info.reason,
        'oldProviders': info.currentProviders, // Keep backup
      });
    } catch (e) {
      print('🔴 Error migrating user $uid: $e');
      rethrow;
    }
  }

  /// ============================================
  /// OPTION 3: Manual User Migration
  /// ============================================
  ///
  /// Migrate một user cụ thể (useful for testing)
  ///
  Future<void> migrateSingleUser(String uid, String correctProvider) async {
    print('🔵 Migrating user $uid to provider: $correctProvider');

    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        print('🔴 User not found');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final currentProviders = List<String>.from(data['providers'] ?? []);

      print('Current providers: $currentProviders');

      await _firestore.collection('users').doc(uid).update({
        'providers': [correctProvider],
        'migratedAt': FieldValue.serverTimestamp(),
        'oldProviders': currentProviders,
      });

      print('✅ Migration successful');
      print('New providers: [$correctProvider]');

    } catch (e) {
      print('🔴 Migration failed: $e');
      rethrow;
    }
  }

  /// ============================================
  /// UTILITY: Check Migration Status
  /// ============================================
  ///
  /// Kiểm tra xem có bao nhiêu users cần migrate
  ///
  Future<void> checkMigrationStatus() async {
    print('🔍 Checking migration status...\n');

    final usersSnapshot = await _firestore.collection('users').get();

    int needMigration = 0;
    int alreadyCorrect = 0;
    int missingProviders = 0;

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final providers = List<String>.from(data['providers'] ?? []);

      if (providers.isEmpty) {
        missingProviders++;
      } else if (providers.length > 1) {
        needMigration++;
      } else {
        alreadyCorrect++;
      }
    }

    print('📊 Status Summary:');
    print('   Total users: ${usersSnapshot.docs.length}');
    print('   ✅ Already single provider: $alreadyCorrect');
    print('   ⚠️  Multiple providers: $needMigration');
    print('   ❓ Missing providers: $missingProviders');
    print('');
    print('Recommendation:');

    if (needMigration > 0 || missingProviders > 0) {
      print('   Run migration with dryRun=true first to preview changes');
      print('   Then run with dryRun=false to apply changes');
    } else {
      print('   All users are already using single provider! 🎉');
    }
  }
}

/// ============================================
/// DATA CLASSES
/// ============================================

class MigrationInfo {
  final String uid;
  final List<String> currentProviders;
  final String correctProvider;
  final String reason;

  MigrationInfo({
    required this.uid,
    required this.currentProviders,
    required this.correctProvider,
    required this.reason,
  });
}

class MigrationResult {
  int totalUsers = 0;
  int usersNeedingMigration = 0;
  int migratedUsers = 0;
  int usersAlreadyCorrect = 0;
  int failedMigrations = 0;
  bool success = false;
  String? errorMessage;

  @override
  String toString() {
    return '''
Migration Result:
  Total: $totalUsers
  Need migration: $usersNeedingMigration
  Migrated: $migratedUsers
  Already correct: $usersAlreadyCorrect
  Failed: $failedMigrations
  Success: $success
  ${errorMessage != null ? 'Error: $errorMessage' : ''}
''';
  }
}

/// ============================================
/// USAGE EXAMPLES
/// ============================================

Future<void> runMigrationExamples() async {
  final migrationService = AuthMigrationService();

  // Example 1: Check status first
  print('=== EXAMPLE 1: Check Status ===\n');
  await migrationService.checkMigrationStatus();

  // Example 2: Dry run (preview changes)
  print('\n=== EXAMPLE 2: Dry Run ===\n');
  await migrationService.migrateAllUsersToSingleProvider(dryRun: true);

  // Example 3: Actually run migration
  // ⚠️ CAUTION: Only run this after reviewing dry run results!
  // print('\n=== EXAMPLE 3: Live Migration ===\n');
  // await migrationService.migrateAllUsersToSingleProvider(dryRun: false);

  // Example 4: Migrate single user for testing
  // await migrationService.migrateSingleUser('user_uid_here', 'password');
}

/// ============================================
/// HOW TO USE THIS SCRIPT
/// ============================================
///
/// Step 1: Add to your Flutter app
/// ```dart
/// import 'package:your_app/services/auth_migration_service.dart';
/// ```
///
/// Step 2: Create a temporary admin screen or run from main()
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///
///   // Run migration
///   final migrationService = AuthMigrationService();
///   await migrationService.checkMigrationStatus();
///
///   runApp(MyApp());
/// }
/// ```
///
/// Step 3: Check status
/// ```dart
/// await migrationService.checkMigrationStatus();
/// ```
///
/// Step 4: Run dry run to preview
/// ```dart
/// await migrationService.migrateAllUsersToSingleProvider(dryRun: true);
/// ```
///
/// Step 5: Review console output
///
/// Step 6: Run actual migration
/// ```dart
/// await migrationService.migrateAllUsersToSingleProvider(dryRun: false);
/// ```
///
/// Step 7: Verify in Firebase Console
///
/// ⚠️ BEST PRACTICE:
/// - Test on a staging environment first
/// - Backup Firestore before running on production
/// - Run during low-traffic hours
/// - Monitor for errors
///
/// 🎯 RECOMMENDED APPROACH:
/// Don't run batch migration at all!
/// Just deploy the new code and let users migrate gradually
/// as they login. The _ensureSingleProvider() method will
/// handle it automatically.
///

