import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../widgets/article_card_horizontal.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ArticleModel> baiViet = [
      ArticleModel(
        title:
        'Scarlett Johansson chia sẻ cô cảm thấy “tuyệt vọng” sau khi mất vai Sandra Bullock',
        source: 'Hollywood Times',
        time: '3 ngày trước',
        imageUrl: 'https://picsum.photos/400/250?random=6',
        link: 'https://hollywoodtimes.com/',
      ),
    ];

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?img=11'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Nguyễn Hoàng Minh Trí',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text('@minhtri123', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bài viết của tôi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children:
              baiViet.map((a) => ArticleCardHorizontal(article: a)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
