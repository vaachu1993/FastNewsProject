import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart';
import '../home/discover_screen.dart';
import '../bookmark/bookmark_screen.dart';
import '../profile/profile_screen.dart';
import '../history/reading_history_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/auth_service.dart';
import '../../services/rss_service.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/localization_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _authService = AuthService();
  int mucHienTai = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  // Add user data
  User? _currentUser;
  Map<String, dynamic>? _userData;

  // Track selected topics (categories)
  List<String> _selectedTopics = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSelectedTopics();

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        _loadUserData();
        _loadSelectedTopics();
      }
    });
  }

  Future<void> _loadUserData() async {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _userData = await _authService.getUserData(_currentUser!.uid);
      setState(() {});
    }
  }

  Future<void> _loadSelectedTopics() async {
    try {
      if (_currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          List<dynamic>? topics;

          // Check selectedTopics first, then fallback to favoriteTopics
          if (data?['selectedTopics'] != null) {
            topics = data?['selectedTopics'] as List<dynamic>?;
          } else if (data?['favoriteTopics'] != null) {
            topics = data?['favoriteTopics'] as List<dynamic>?;
          }

          if (topics != null) {
            setState(() {
              _selectedTopics = topics!.map((e) => e.toString()).toList();
            });
          }
        }
      }
    } catch (e) {
      print('Error loading selected topics: $e');
    }
  }

  Future<void> _toggleTopic(String category) async {
    if (category == 'Tất cả') return; // Don't allow toggling "All"

    setState(() {
      if (_selectedTopics.contains(category)) {
        _selectedTopics.remove(category);
      } else {
        _selectedTopics.add(category);
      }
    });

    // Save to Firestore
    await _saveSelectedTopics();

    // 🎯 Trigger reload HomeScreen với animation
    if (mucHienTai == 0) {
      // Nếu đang ở HomeScreen, reload ngay
      _homeScreenKey.currentState?.reloadWithAnimation();
    }
  }

  Future<void> _saveSelectedTopics() async {
    try {
      if (_currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .set({
          'selectedTopics': _selectedTopics,
          'favoriteTopics': _selectedTopics,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Saved selected topics: $_selectedTopics');
      }
    } catch (e) {
      print('❌ Error saving selected topics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    // Create pages with keys based on language to force rebuild when language changes
    final pages = [
      HomeScreen(
        key: _homeScreenKey, // Use GlobalKey để access state
        onNavigateToProfile: () {
          setState(() => mucHienTai = 3);
        },
      ),
      DiscoverScreen(key: ValueKey('discover_$currentLanguage')),
      BookmarkScreen(key: ValueKey('bookmark_$currentLanguage')),
      ProfileScreen(key: ValueKey('profile_$currentLanguage')),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, loc),
      body: IndexedStack(
        index: mucHienTai,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
            currentIndex: mucHienTai,
            onTap: (value) {
              setState(() => mucHienTai = value);
            },
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: loc.home),
              BottomNavigationBarItem(icon: const Icon(Icons.search), label: loc.discover),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.bookmark_outline), label: loc.bookmarks),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline), label: loc.profile),
            ],
          ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations loc) {
    return Drawer(
      backgroundColor: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF5A7D3C),
                    backgroundImage: (_userData?['photoURL'] != null && _userData!['photoURL'].toString().isNotEmpty) ||
                            (_currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty)
                        ? NetworkImage(_userData?['photoURL'] ?? _currentUser?.photoURL ?? '')
                        : null,
                    child: (_userData?['photoURL'] == null || _userData!['photoURL'].toString().isEmpty) &&
                            (_currentUser?.photoURL == null || _currentUser!.photoURL!.isEmpty)
                        ? Text(
                            (_userData?['displayName'] ?? _currentUser?.displayName ?? _userData?['email'] ?? _currentUser?.email ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData?['displayName'] ?? _currentUser?.displayName ?? loc.translate('user'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userData?['email'] ?? _currentUser?.email ?? '',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2C2C2E), height: 1),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    icon: Icons.diamond_outlined,
                    title: loc.translate('today'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => mucHienTai = 0);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.bookmark_outline,
                    title: loc.translate('read_later'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => mucHienTai = 2);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Categories section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          loc.translate('categories'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedTopics.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_selectedTopics.length}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Generate category menu items dynamically with checkboxes
                  ...RssService.getCategories().map((category) {
                    final localizationProvider = LocalizationProvider.of(context);
                    final lang = localizationProvider?.currentLanguage ?? 'vi';
                    final translatedCategory = _translateCategory(category, lang);
                    final icon = _getCategoryIcon(category);
                    final isSelected = _selectedTopics.contains(category);
                    final isAllCategory = category == 'Tất cả';

                    return _buildCategoryMenuItem(
                      icon: icon,
                      title: translatedCategory,
                      isSelected: isSelected,
                      isAllCategory: isAllCategory,
                      onTap: () async {
                        if (!isAllCategory) {
                          await _toggleTopic(category);
                        }
                      },
                    );
                  }),


                  const Divider(color: Color(0xFF2C2C2E), height: 32),

                  // Bottom menu items
                  _buildMenuItem(
                    icon: Icons.history,
                    title: loc.translate('recently_read'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReadingHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: loc.translate('settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[400], size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildCategoryMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isAllCategory,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.green : Colors.grey[400],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green : Colors.white,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: isAllCategory
          ? null
          : Checkbox(
              value: isSelected,
              onChanged: (value) => onTap(),
              activeColor: Colors.green,
              checkColor: Colors.white,
              side: BorderSide(color: Colors.grey[600]!),
            ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Translate category based on current language
  String _translateCategory(String category, String currentLanguage) {
    if (currentLanguage == 'en') {
      switch (category) {
        case 'Tất cả':
          return 'All';
        case 'Chính trị':
          return 'Politics';
        case 'Kinh doanh':
          return 'Business';
        case 'Công nghệ':
          return 'Technology';
        case 'Thể thao':
          return 'Sports';
        case 'Sức khỏe':
          return 'Health';
        case 'Đời sống':
          return 'Lifestyle';
        default:
          return category;
      }
    }
    return category;
  }

  // Get icon for each category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tất cả':
        return Icons.apps;
      case 'Chính trị':
        return Icons.gavel;
      case 'Kinh doanh':
        return Icons.business;
      case 'Công nghệ':
        return Icons.computer;
      case 'Thể thao':
        return Icons.sports_soccer;
      case 'Sức khỏe':
        return Icons.health_and_safety;
      case 'Đời sống':
        return Icons.home;
      default:
        return Icons.chevron_right;
    }
  }
}
