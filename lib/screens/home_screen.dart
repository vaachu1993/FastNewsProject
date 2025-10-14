import 'package:flutter/material.dart';
import '../widgets/article_card.dart'; // widget hiển thị từng bài
import '../models/article_model.dart'; // dữ liệu mẫu bài viết

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Danh mục tin tức
  final List<String> categories = [
    'Tất cả',
    'Công nghệ',
    'Thể thao',
    'Giải trí',
    'Kinh tế',
    'Thế giới',
    'Sức khỏe',
  ];

  // Vị trí danh mục được chọn
  int selectedIndex = 0;

  // Dữ liệu bài viết mẫu (sau này bạn có thể thay bằng API)
  final List<ArticleModel> articles = [
    ArticleModel(
      title: 'AI đang thay đổi cách con người tiếp cận tin tức',
      source: 'VNExpress',
      time: '2 giờ trước',
      imageUrl: 'https://picsum.photos/400/200?random=1',
    ),
    ArticleModel(
      title: 'Google ra mắt tính năng tìm kiếm thế hệ mới',
      source: 'ZingNews',
      time: '4 giờ trước',
      imageUrl: 'https://picsum.photos/400/200?random=2',
    ),
    ArticleModel(
      title: 'Bóng đá Việt Nam chuẩn bị cho AFF Cup 2025',
      source: 'Thanh Niên',
      time: '6 giờ trước',
      imageUrl: 'https://picsum.photos/400/200?random=3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Text(
              "Fast",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const Text(
              "News",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.newspaper, color: Colors.blueAccent),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.black87),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline, color: Colors.black87),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh danh mục
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final bool isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Danh sách bài viết
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return ArticleCard(article: articles[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
