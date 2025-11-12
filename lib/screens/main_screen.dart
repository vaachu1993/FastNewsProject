import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'bookmark_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _authService = AuthService();
  int mucHienTai = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> pages = const [
    HomeScreen(),
    DiscoverScreen(),
    BookmarkScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Khám phá'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline), label: 'Đánh dấu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                    backgroundColor: Colors.green,
                    child: Text(
                      (_authService.currentUser?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _authService.currentUser?.displayName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _authService.currentUser?.email ?? '',
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
                    title: 'Hôm nay',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => mucHienTai = 0);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.bookmark_outline,
                    title: 'Đọc sau',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => mucHienTai = 2);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Thể loại section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Thể loại',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.menu,
                    title: 'Tất cả',
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
                    title: 'Công nghệ',
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
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Thêm nội dung'),
                      ),
                    ),
                  ),

                  const Divider(color: Color(0xFF2C2C2E), height: 32),

                  // Bottom menu items
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Đã đọc gần đây',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.palette_outlined,
                    title: 'Chọn giao diện',
                    onTap: () {
                      Navigator.pop(context);
                      _showThemeDialog(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Cài đặt',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => mucHienTai = 3);
                    },
                  ),
                ],
              ),
            ),

            // Logout button
            Container(
              padding: const EdgeInsets.all(8),
              child: _buildMenuItem(
                icon: Icons.logout,
                title: 'Đăng xuất',
                onTap: () async {
                  Navigator.pop(context);
                  await _authService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
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

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Choose Theme',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode, color: Colors.white),
              title: const Text('Light', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Colors.white),
              title: const Text('Dark', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto, color: Colors.white),
              title: const Text('System', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              'Upgrade to PRO',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Get unlimited access to all features!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
