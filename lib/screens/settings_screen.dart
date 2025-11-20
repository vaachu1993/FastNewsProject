import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/app_localizations.dart';
import '../widgets/localization_provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'help_screen.dart';

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
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    setState(() => _pushNotifications = value);
    await _notificationService.setNotificationsEnabled(value);

    if (!mounted) return;

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? loc.notificationEnabled : loc.notificationDisabled,
        ),
        backgroundColor: value ? Colors.green : Colors.grey[700],
        duration: const Duration(seconds: 2),
        action: value ? SnackBarAction(
          label: loc.testNotification,
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
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    // Sync _selectedLanguage with currentLanguage
    _selectedLanguage = currentLanguage == 'vi' ? 'Tiếng Việt' : 'English';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.settings,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
            title: loc.account,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          _buildSimpleDivider(),

          // Notifications
          _buildSwitchListTile(
            icon: Icons.notifications_outlined,
            title: loc.notifications,
            value: _pushNotifications,
            onChanged: _isLoadingNotificationState ? null : (val) => _toggleNotifications(val),
          ),
          _buildSimpleDivider(),

          // Dark Mode
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSwitchListTile(
                icon: Icons.dark_mode_outlined,
                title: loc.darkMode,
                value: themeProvider.isDarkMode,
                onChanged: (val) async {
                  await themeProvider.setDarkMode(val);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val
                            ? (currentLanguage == 'vi' ? '🌙 Đã bật chế độ tối' : '🌙 Dark mode enabled')
                            : (currentLanguage == 'vi' ? '☀️ Đã bật chế độ sáng' : '☀️ Light mode enabled'),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
          _buildSimpleDivider(),

          // Language
          _buildSimpleListTile(
            icon: Icons.language,
            title: loc.language,
            onTap: () => _showLanguageDialog(loc),
          ),
          _buildSimpleDivider(),


          // Terms & Conditions
          _buildSimpleListTile(
            icon: Icons.description_outlined,
            title: loc.termsAndConditions,
            onTap: () => _showTermsOfService(loc),
          ),
          _buildSimpleDivider(),

          // Privacy Policy
          _buildSimpleListTile(
            icon: Icons.privacy_tip_outlined,
            title: loc.privacyPolicy,
            onTap: () => _showPrivacyPolicy(loc),
          ),
          _buildSimpleDivider(),

          // Help
          _buildSimpleListTile(
            icon: Icons.help_outline,
            title: loc.help,
            onTap: () => _showHelp(loc),
          ),
          _buildSimpleDivider(),

          // Logout
          _buildSimpleListTile(
            icon: Icons.logout,
            title: loc.logout,
            onTap: () => _showLogoutDialog(loc),
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
        color: Theme.of(context).iconTheme.color,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).textTheme.bodySmall?.color,
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
        color: Theme.of(context).iconTheme.color,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.green.shade300,
        activeThumbColor: Colors.green,
      ),
    );
  }

  // Simple divider
  Widget _buildSimpleDivider() {
    return Divider(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey[300],
      height: 1,
      indent: 64,
      endIndent: 0,
    );
  }

  // Dialog methods
  void _showLanguageDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2740)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          loc.selectLanguage,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
              dialogContext,
              loc.vietnamese,
              _selectedLanguage == 'Tiếng Việt',
              'vi',
            ),
            _buildDialogOption(
              dialogContext,
              loc.english,
              _selectedLanguage == 'English',
              'en',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOption(
    BuildContext dialogContext,
    String title,
    bool isSelected,
    String languageCode,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).iconTheme.color)
          : null,
      onTap: () async {
        Navigator.pop(dialogContext);

        // Change language via LocalizationProvider
        final localizationProvider = LocalizationProvider.of(context);
        if (localizationProvider != null) {
          await localizationProvider.changeLanguage(languageCode);
        }

        // Update selected language display
        setState(() {
          _selectedLanguage = languageCode == 'vi' ? 'Tiếng Việt' : 'English';
        });

        if (mounted) {
          // Show confirmation
          final newLoc = AppLocalizations(languageCode);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${newLoc.language}: $title'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }


  void _showTermsOfService(AppLocalizations loc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsScreen(),
      ),
    );
  }

  void _showPrivacyPolicy(AppLocalizations loc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyScreen(),
      ),
    );
  }

  void _showHelp(AppLocalizations loc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpScreen(),
      ),
    );
  }

  Future<void> _showLogoutDialog(AppLocalizations loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2740)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.logout,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          loc.logoutConfirm,
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              loc.cancel,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.logout),
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
              content: Text('${loc.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

