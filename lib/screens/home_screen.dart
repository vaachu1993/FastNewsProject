import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../widgets/article_card_horizontal.dart';
import '../services/rss_service.dart'; // ← dùng để tải tin từ RSS

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int danhMucDuocChon = 0;
  bool isLoading = true;
  List<ArticleModel> tinMoiNhat = [];

  final List<String> danhMuc = [
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
    _taiTinMoiNhat();
  }

  Future<void> _taiTinMoiNhat() async {
    final news = await RssService.fetchLatestNews(); // 🔹 gọi RSS service
    setState(() {
      tinMoiNhat = news;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: _taiTinMoiNhat, // 🔹 làm mới tin tức
          ),
          const Icon(Icons.notifications_outlined, color: Colors.black87),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 15,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
          ),
          const SizedBox(width: 12),
        ],
      ),

      // 📰 Nội dung trang
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.green),
      )
          : RefreshIndicator(
        onRefresh: _taiTinMoiNhat,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧠 Tiêu đề
              const Text(
                'Tin mới nhất',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // 🔥 Danh sách tin mới nhất từ RSS
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tinMoiNhat.length,
                itemBuilder: (context, index) {
                  return ArticleCardHorizontal(
                    article: tinMoiNhat[index],
                  );
                },
              ),

              const SizedBox(height: 20),
              const Text(
                'Tin thế giới',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Ví dụ phần tin cố định cũ của bạn (nếu muốn giữ lại)
              Column(
                children: tinMoiNhat.take(3).map((a) {
                  return ArticleCardHorizontal(article: a);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
