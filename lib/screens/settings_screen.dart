import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  bool _isLoadingNotificationState = true;

  // Settings states
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _selectedLanguage = 'Tiếng Việt';

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    setState(() {
      _pushNotifications = enabled;
      _isLoadingNotificationState = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _pushNotifications = value);
    await _notificationService.setNotificationsEnabled(value);

    if (!mounted) return;

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
            ? '✅ Đã bật thông báo tin tức mới'
            : '🔕 Đã tắt thông báo tin tức mới',
        ),
        backgroundColor: value ? Colors.green : Colors.grey[700],
        duration: const Duration(seconds: 2),
        action: value ? SnackBarAction(
          label: 'Thử nghiệm',
          textColor: Colors.white,
          onPressed: () async {
            await _notificationService.sendTestNotification();
          },
        ) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Account
          _buildSimpleListTile(
            icon: Icons.person_outline,
            title: 'Tài khoản',
            onTap: () {
              // Navigate to account details
            },
          ),
          _buildSimpleDivider(),

          // Notifications
          _buildSwitchListTile(
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            value: _pushNotifications,
            onChanged: _isLoadingNotificationState ? null : (val) => _toggleNotifications(val),
          ),
          _buildSimpleDivider(),

          // Dark Mode
          _buildSwitchListTile(
            icon: Icons.dark_mode_outlined,
            title: 'Chế độ tối',
            value: _darkMode,
            onChanged: (val) => setState(() => _darkMode = val),
          ),
          _buildSimpleDivider(),

          // Language
          _buildSimpleListTile(
            icon: Icons.language,
            title: 'Ngôn ngữ',
            onTap: () => _showLanguageDialog(),
          ),
          _buildSimpleDivider(),

          // Security
          _buildSimpleListTile(
            icon: Icons.security_outlined,
            title: 'Bảo mật',
            onTap: () => _showSecuritySettings(),
          ),
          _buildSimpleDivider(),

          // Terms & Conditions
          _buildSimpleListTile(
            icon: Icons.description_outlined,
            title: 'Điều khoản & Điều kiện',
            onTap: () => _showTermsOfService(),
          ),
          _buildSimpleDivider(),

          // Privacy Policy
          _buildSimpleListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Chính sách bảo mật',
            onTap: () => _showPrivacyPolicy(),
          ),
          _buildSimpleDivider(),

          // Help
          _buildSimpleListTile(
            icon: Icons.help_outline,
            title: 'Trợ giúp',
            onTap: () => _showHelp(),
          ),
          _buildSimpleDivider(),

          // Invite a friend
          _buildSimpleListTile(
            icon: Icons.person_add_outlined,
            title: 'Mời bạn bè',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng mời bạn bè sắp ra mắt'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          _buildSimpleDivider(),

          // Logout
          _buildSimpleListTile(
            icon: Icons.logout,
            title: 'Đăng xuất',
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  // Simple list tile for navigation items
  Widget _buildSimpleListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Icon(
        icon,
        color: Colors.black87,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.black54,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  // Switch list tile for toggle settings
  Widget _buildSwitchListTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon,
        color: Colors.black87,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.black54,
        activeThumbColor: Colors.black87,
      ),
    );
  }

  // Simple divider
  Widget _buildSimpleDivider() {
    return Divider(
      color: Colors.grey[300],
      height: 1,
      indent: 64,
      endIndent: 0,
    );
  }

  // Dialog methods
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Chọn ngôn ngữ',
          style: TextStyle(color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption('Tiếng Việt', _selectedLanguage == 'Tiếng Việt'),
            _buildDialogOption('English', _selectedLanguage == 'English'),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOption(String title, bool isSelected) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.black87)
          : null,
      onTap: () {
        setState(() {
          _selectedLanguage = title;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showSecuritySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cài đặt bảo mật sắp ra mắt'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang mở Điều khoản & Điều kiện...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang mở Chính sách bảo mật...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang mở Trợ giúp...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.black87),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

