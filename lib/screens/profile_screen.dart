import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _userData = await _authService.getUserData(_currentUser!.uid);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Trang cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
            tooltip: 'Đăng xuất',
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
                          _userData?['displayName'] ?? _currentUser?.displayName ?? 'Người dùng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        if (_userData?['emailVerified'] == true) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Email đã xác thực',
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
                      _userData?['email'] ?? _currentUser?.email ?? 'Không có email',
                      style: const TextStyle(color: Colors.grey),
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
                              'Tên',
                              _userData?['displayName'] ?? _currentUser?.displayName ?? 'Chưa cập nhật',
                            ),
                            const Divider(),
                            _buildInfoRow(
                              Icons.email,
                              'Email',
                              _userData?['email'] ?? _currentUser?.email ?? 'Chưa cập nhật',
                            ),
                            const Divider(),
                            _buildVerificationRow(),
                            const Divider(),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Tham gia',
                              _currentUser?.metadata.creationTime != null
                                  ? _formatDate(_currentUser!.metadata.creationTime!)
                                  : 'Chưa xác định',
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
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
          const Text(
            'Trạng thái:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
                        isVerified ? 'Đã xác thực' : 'Chưa xác thực',
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
