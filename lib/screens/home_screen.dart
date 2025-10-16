import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../widgets/article_card_horizontal.dart';
import '../services/rss_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategory = 0;
  bool isLoading = true;
  List<ArticleModel> latestNews = [];

  final List<String> categories = [
    'Tất cả',
    'Chính trị',
    'Công nghệ',
    'Kinh doanh',
    'Thể thao',
    'Sức khỏe',
  ];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final news = await RssService.fetchLatestNews();
    setState(() {
      latestNews = news;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.network(
              'https://img.icons8.com/color/48/news.png',
              width: 28,
              height: 28,
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
          Icon(Icons.notifications_outlined, color: Colors.black87),
          SizedBox(width: 10),
          CircleAvatar(
            radius: 15,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
        onRefresh: _loadNews,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 Tiêu đề Trending News
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tin nổi bật',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),

              // 🏷️ Danh mục
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final bool isSelected = selectedCategory == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedCategory = index);
                      },
                      child: Container(
                        margin:
                        const EdgeInsets.only(right: 10, bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color:
                            isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // 📰 Danh sách tin nổi bật (trượt ngang)
              SizedBox(
                height: 320,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: latestNews.length.clamp(0, 5),
                  itemBuilder: (context, index) {
                    return Container(
                      width: 300,
                      margin: const EdgeInsets.only(right: 14),
                      child:
                      ArticleCardHorizontal(article: latestNews[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 🌍 Global Stories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tin toàn cầu',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Danh sách tin dọc (Global Stories)
              Column(
                children: latestNews
                    .skip(5)
                    .take(5)
                    .map((a) => ArticleCardHorizontal(article: a))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
