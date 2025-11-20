import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'bookmark_screen.dart';
import 'profile_screen.dart';
import 'reading_history_screen.dart';
import 'settings_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_localizations.dart';
import '../widgets/localization_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _authService = AuthService();
  int mucHienTai = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add user data
  User? _currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        _loadUserData();
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

  @override
  Widget build(BuildContext context) {
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    // Create pages with keys based on language to force rebuild when language changes
    final pages = [
      HomeScreen(key: ValueKey('home_$currentLanguage')),
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
                    child: Text(
                      loc.translate('categories'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.menu,
                    title: loc.translate('all'),
                    trailing: Text(
                      '463',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => mucHienTai = 0);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.chevron_right,
                    title: loc.translate('technology'),
                    trailing: Text(
                      '453',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => mucHienTai = 0);
                    },
                  ),

                  // Add Content button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                        side: BorderSide(color: Colors.grey[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(loc.translate('add_content')),
                      ),
                    ),
                  ),

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


}
