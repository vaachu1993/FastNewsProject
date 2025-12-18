import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../screens/home/article_detail_screen.dart'; // 👈 để mở trang chi tiết
import '../utils/date_formatter.dart';
import 'safe_network_image.dart';

class ArticleCardHorizontal extends StatelessWidget {
  final ArticleModel article;
  final bool isHorizontalList;

  const ArticleCardHorizontal({
    super.key,
    required this.article,
    this.isHorizontalList = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 👇 Khi bấm vào card → mở trang chi tiết
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        width: isHorizontalList ? 280 : double.infinity,
        margin: isHorizontalList
            ? const EdgeInsets.only(right: 16)
            : const EdgeInsets.only(bottom: 12),
        child: Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.hardEdge,
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 Ảnh bài viết
              CachedSafeImage(
                imageUrl: article.imageUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),

              // 🧾 Nội dung tóm tắt
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Tiêu đề
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 🏷 Nguồn báo
                    Text(
                      article.source.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 🕒 Thời gian + menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.formatDateTime(article.time),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Icon(Icons.more_vert,
                            color: Colors.grey, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
