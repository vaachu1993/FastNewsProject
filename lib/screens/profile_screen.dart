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
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.network(
              'https://img.icons8.com/color/48/news.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 8),
            const Text(
              'FastNews',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.settings_outlined, color: Colors.black87),
          SizedBox(width: 10),
          Icon(Icons.share_outlined, color: Colors.black87),
          SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Avatar & Thông tin cá nhân
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?img=11'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nguyễn Hoàng Minh Trí',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const Text(
                    '@minhtri123',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  // Thống kê follower
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Column(
                        children: [
                          Text(
                            '1,234',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text('Người theo dõi',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      SizedBox(width: 30),
                      Column(
                        children: [
                          Text(
                            '123',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text('Đang theo dõi',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Mô tả bản thân
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Là người yêu thích công nghệ và tin tức, '
                          'tôi chia sẻ các câu chuyện hấp dẫn về thế giới số và xu hướng hiện đại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'www.fastnews.vn/minhtri',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🧾 Tiêu đề danh sách bài viết
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bài viết của tôi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Tạo mới',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 📚 Danh sách bài viết
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
