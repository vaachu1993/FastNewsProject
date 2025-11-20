import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';

class TopicsSelectionScreen extends StatefulWidget {
  final bool isFromSettings; // True if opened from Settings, false if from registration

  const TopicsSelectionScreen({super.key, this.isFromSettings = false});

  @override
  State<TopicsSelectionScreen> createState() => _TopicsSelectionScreenState();
}

class _TopicsSelectionScreenState extends State<TopicsSelectionScreen> {
  final List<TopicModel> _topics = [
    TopicModel(
      id: 'Chính trị',
      name: '🏛️ Chính trị',
      icon: Icons.account_balance,
      color: const Color(0xFF34495E),
    ),
    TopicModel(
      id: 'Công nghệ',
      name: '💻 Công nghệ',
      icon: Icons.computer,
      color: const Color(0xFF4A90E2),
    ),
    TopicModel(
      id: 'Kinh doanh',
      name: '💼 Kinh doanh',
      icon: Icons.business_center,
      color: const Color(0xFF50C878),
    ),
    TopicModel(
      id: 'Thể thao',
      name: '⚽ Thể thao',
      icon: Icons.sports_soccer,
      color: const Color(0xFFFF6B6B),
    ),
    TopicModel(
      id: 'Sức khỏe',
      name: '🏥 Sức khỏe',
      icon: Icons.favorite,
      color: const Color(0xFF48C9B0),
    ),
    TopicModel(
      id: 'Đời sống',
      name: '🎭 Đời sống',
      icon: Icons.people,
      color: const Color(0xFFFF69B4),
    ),
  ];

  final Set<String> _selectedTopics = {};
  bool _isLoading = false;
  bool _isLoadingTopics = true;

  @override
  void initState() {
    super.initState();
    if (widget.isFromSettings) {
      _loadExistingTopics();
    } else {
      setState(() => _isLoadingTopics = false);
    }
  }

  Future<void> _loadExistingTopics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            // Check selectedTopics first, then fallback to favoriteTopics
            List<dynamic>? topics;
            if (data['selectedTopics'] != null) {
              topics = data['selectedTopics'] as List<dynamic>;
            } else if (data['favoriteTopics'] != null) {
              topics = data['favoriteTopics'] as List<dynamic>;
            }

            if (topics != null && topics.isNotEmpty) {
              setState(() {
                _selectedTopics.addAll(topics!.map((e) => e.toString()).toList());
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading existing topics: $e');
    } finally {
      setState(() => _isLoadingTopics = false);
    }
  }

  Future<void> _saveTopicsAndContinue() async {
    if (_selectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one topic'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Lấy document hiện tại để check xem đã có dữ liệu chưa
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();

        // Chuẩn bị dữ liệu để lưu
        Map<String, dynamic> userData = {
          'selectedTopics': _selectedTopics.toList(), // Primary field (from registration)
          'favoriteTopics': _selectedTopics.toList(), // For backward compatibility
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Nếu là user mới (chưa có document), thêm thông tin cơ bản
        if (!docSnapshot.exists) {
          userData.addAll({
            'email': user.email ?? '',
            'displayName': user.displayName ?? '',
            'photoURL': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Lưu topics và thông tin user vào Firestore
        await docRef.set(userData, SetOptions(merge: true));

        if (!mounted) return;

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved ${_selectedTopics.length} topics!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Chuyển đến MainScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving topics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skipForNow() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Choose Your Interests',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select topics you\'re interested in to personalize your news feed',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedTopics.length} selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedTopics.isEmpty ? Colors.grey : const Color(0xFF5A7D3C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Topics Grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _topics.map((topic) {
                    final isSelected = _selectedTopics.contains(topic.id);
                    return _buildTopicChip(topic, isSelected);
                  }).toList(),
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTopicsAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A7D3C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Skip Button
                  TextButton(
                    onPressed: _isLoading ? null : _skipForNow,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF808080),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicChip(TopicModel topic, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTopics.remove(topic.id);
          } else {
            _selectedTopics.add(topic.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? topic.color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? topic.color : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              topic.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? topic.color : const Color(0xFF2C2C2C),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 18,
                color: topic.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Model for Topic
class TopicModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  TopicModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

