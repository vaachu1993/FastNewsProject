import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../widgets/article_card_horizontal.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ArticleModel> daLuu = [
      ArticleModel(
        title: 'Việt Nam sẽ trở thành trung tâm AI hàng đầu Đông Nam Á?',
        source: 'Thanh Niên',
        time: 'Hôm qua',
        imageUrl: 'https://picsum.photos/400/250?random=10',
        link: 'https://thanhnien.vn/',
      ),
      ArticleModel(
        title: 'Ứng dụng FastNews đạt 1 triệu lượt tải trên CH Play',
        source: 'FastNews Blog',
        time: '2 ngày trước',
        imageUrl: 'https://picsum.photos/400/250?random=11',
        link: 'https://fastnews.vn/',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Tin đã lưu',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: daLuu.isEmpty
          ? const Center(
        child: Text(
          'Bạn chưa lưu bài viết nào.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bài viết đã đánh dấu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: daLuu.length,
                itemBuilder: (context, index) {
                  return ArticleCardHorizontal(article: daLuu[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
