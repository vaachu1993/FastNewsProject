import 'package:fastnews/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../widgets/article_card_horizontal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int danhMucDuocChon = 0;

  final List<String> danhMuc = [
    'Tất cả',
    'Chính trị',
    'Công nghệ',
    'Kinh doanh',
    'Thể thao',
    'Sức khỏe',
  ];

  final List<ArticleModel> tinNoiBat = [
    ArticleModel(
      title: 'AI đang thay đổi cách con người tiếp cận tin tức mỗi ngày',
      source: 'VNExpress',
      time: '3 giờ trước',
      imageUrl: 'https://picsum.photos/400/250?random=1',
    ),
    ArticleModel(
      title: 'Việt Nam hướng tới chuyển đổi số toàn diện trong năm 2025',
      source: 'Thanh Niên',
      time: '6 giờ trước',
      imageUrl: 'https://picsum.photos/400/250?random=2',
    ),
  ];

  final List<ArticleModel> tinToanCau = [
    ArticleModel(
      title: 'Công nghệ AI đang mở ra kỷ nguyên mới cho ngành y tế',
      source: 'BBC News',
      time: '1 ngày trước',
      imageUrl: 'https://picsum.photos/400/250?random=3',
    ),
    ArticleModel(
      title: 'Thị trường chứng khoán toàn cầu phục hồi mạnh mẽ',
      source: 'Bloomberg',
      time: '2 ngày trước',
      imageUrl: 'https://picsum.photos/400/250?random=4',
    ),
  ];

  int mucHienTai = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🧭 Thanh AppBar
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
          Icon(Icons.notifications_outlined, color: Colors.black87),
          SizedBox(width: 12),
          CircleAvatar(
            radius: 15,
            backgroundImage:
            NetworkImage('https://i.pravatar.cc/150?img=12'),
          ),
          SizedBox(width: 12),
        ],
      ),

      // 📰 Nội dung trang
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 Tiêu đề "Tin nổi bật"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tin nổi bật',
                    style: TextStyle(
                      fontSize: 20,
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
                  itemCount: danhMuc.length,
                  itemBuilder: (context, index) {
                    final duocChon = danhMucDuocChon == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          danhMucDuocChon = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: duocChon ? Colors.green : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          danhMuc[index],
                          style: TextStyle(
                            color: duocChon ? Colors.white : Colors.black,
                            fontWeight:
                            duocChon ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 🗞️ Danh sách tin nổi bật
              SizedBox(
                height: 310,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tinNoiBat.length,
                  itemBuilder: (context, index) {
                    return ArticleCardHorizontal(article: tinNoiBat[index]);
                  },
                ),
              ),

              const SizedBox(height: 10),

              // 🌍 Tin toàn cầu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tin thế giới',
                    style: TextStyle(
                      fontSize: 20,
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

              // Danh sách tin dọc
              Column(
                children: tinToanCau.map((a) {
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
