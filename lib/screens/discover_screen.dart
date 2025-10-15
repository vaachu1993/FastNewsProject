import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../widgets/article_card_horizontal.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ArticleModel> deXuat = [
      ArticleModel(
        title: '10 xu hướng công nghệ nổi bật năm 2025 bạn nên biết',
        source: 'VNExpress',
        time: '2 giờ trước',
        imageUrl: 'https://picsum.photos/400/250?random=7',
        link: 'https://vnexpress.net/rss/tin-moi-nhat.rss',
      ),
      ArticleModel(
        title: 'ChatGPT và tương lai trí tuệ nhân tạo trong đời sống',
        source: 'Zing News',
        time: '5 giờ trước',
        imageUrl: 'https://picsum.photos/400/250?random=8',
        link: 'https://zingnews.vn/',
      ),
      ArticleModel(
        title: 'Du lịch vũ trụ – khi giấc mơ ra ngoài không gian dần trở thành hiện thực',
        source: 'BBC Future',
        time: '1 ngày trước',
        imageUrl: 'https://picsum.photos/400/250?random=9',
        link: 'https://www.bbc.com/future',
      ),
    ];

    final List<String> tags = [
      'Công nghệ',
      'Giải trí',
      'Khoa học',
      'Thể thao',
      'Kinh tế',
      'Đời sống',
      'Du lịch',
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Khám phá',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tin tức...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tags[index],
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tin tức nổi bật',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: deXuat.map((a) => ArticleCardHorizontal(article: a)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
