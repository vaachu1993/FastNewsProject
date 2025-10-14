import 'package:flutter/material.dart';
import '../models/article_model.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;

  const ArticleCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      elevation: 2,
      child: InkWell(
        onTap: () {
          // TODO: chuyển sang màn chi tiết bài viết
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(article.imageUrl, fit: BoxFit.cover, width: double.infinity, height: 180),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(article.source, style: const TextStyle(color: Colors.grey)),
                      Text(article.time, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
