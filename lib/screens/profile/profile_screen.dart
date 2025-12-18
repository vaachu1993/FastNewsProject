import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/localization_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // Track language to reload on change
  String? _previousLanguage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check for language change
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';

    if (_previousLanguage != null && _previousLanguage != currentLanguage) {
      // Language changed, just update UI
      _previousLanguage = currentLanguage;
      if (mounted) {
        setState(() {});
      }
    } else if (_previousLanguage == null) {
      _previousLanguage = currentLanguage;
    }
  }

  Future<void> _loadUserData() async {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _userData = await _authService.getUserData(_currentUser!.uid);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleLogout() async {
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.translate('logout_dialog_title')),
        content: Text(loc.translate('logout_dialog_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.translate('logout')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          loc.profile,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
            tooltip: loc.translate('logout_tooltip'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Column(
                  children: [
                    _buildProfileAvatar(),
                    const SizedBox(height: 10),
                      Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userData?['displayName'] ?? _currentUser?.displayName ?? loc.translate('user'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        if (_userData?['emailVerified'] == true) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: loc.translate('email_verified_tooltip'),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _userData?['email'] ?? _currentUser?.email ?? loc.translate('no_email'),
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 16),
                    // User info card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.person,
                              loc.translate('name_label'),
                              _userData?['displayName'] ?? _currentUser?.displayName ?? loc.translate('not_updated'),
                            ),
                            const Divider(),
                            _buildInfoRow(
                              Icons.email,
                              loc.translate('email_label'),
                              _userData?['email'] ?? _currentUser?.email ?? loc.translate('not_updated'),
                            ),
                            const Divider(),
                            _buildVerificationRow(),
                            const Divider(),
                            _buildInfoRow(
                              Icons.calendar_today,
                              loc.translate('joined_label'),
                              _currentUser?.metadata.creationTime != null
                                  ? _formatDate(_currentUser!.metadata.creationTime!)
                                  : loc.translate('not_determined'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileAvatar() {
    final photoURL = _userData?['photoURL']?.toString() ?? _currentUser?.photoURL ?? '';
    final displayName = _userData?['displayName'] ?? _currentUser?.displayName ?? '';
    final email = _userData?['email'] ?? _currentUser?.email ?? '';

    // Get first letter for fallback
    final firstLetter = (displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email : 'U'))[0].toUpperCase();

    // Check if we have a valid photo URL
    final hasValidPhoto = photoURL.isNotEmpty &&
                          (photoURL.startsWith('http://') || photoURL.startsWith('https://'));

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF5A7D3C),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasValidPhoto
            ? Image.network(
                photoURL,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Show fallback on error
                  return _buildAvatarFallback(firstLetter);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
              )
            : _buildAvatarFallback(firstLetter),
      ),
    );
  }

  Widget _buildAvatarFallback(String letter) {
    return Container(
      color: const Color(0xFF5A7D3C),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5A7D3C), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRow() {
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    final isVerified = _userData?['emailVerified'] == true;
    final verificationMethod = _userData?['verificationMethod'] ?? 'unknown';

    String methodText = '';
    if (verificationMethod == 'otp') {
      methodText = 'Email';
    } else if (verificationMethod == 'google') {
      methodText = 'Google';
    } else {
      methodText = verificationMethod;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.warning_amber,
            color: isVerified ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '${loc.translate('status_label')}:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isVerified ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified ? Icons.check_circle : Icons.error_outline,
                        size: 14,
                        color: isVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? loc.translate('verified') : loc.translate('not_verified'),
                        style: TextStyle(
                          color: isVerified ? Colors.green.shade700 : Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  Text(
                    '($methodText)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
