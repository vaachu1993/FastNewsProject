import 'package:flutter_test/flutter_test.dart';
import 'package:fastnews/services/rss_service.dart';
import 'package:fastnews/utils/content_deduplication.dart';

void main() {
  test('Kiểm tra bài trùng lặp trong danh mục Công nghệ', () async {
    print("\n🔍 === KIỂM TRA BÀI TRÙNG LẶP DANH MỤC CÔNG NGHỆ ===\n");

    // Lấy tin tức từ danh mục Công nghệ
    final articles = await RssService.fetchNewsByCategory('Công nghệ');

    print("📊 Tổng số bài viết: ${articles.length}\n");

    // Hiển thị tất cả các bài viết
    print("📰 DANH SÁCH BÀI VIẾT:");
    for (int i = 0; i < articles.length; i++) {
      final article = articles[i];
      print("${i + 1}. [${article.source}] ${article.title}");
      if (article.description != null && article.description!.isNotEmpty) {
        print("   📝 ${article.description!.substring(0, article.description!.length > 100 ? 100 : article.description!.length)}...");
      }
      print("");
    }

    // Tìm các bài về AI
    final aiArticles = articles.where((a) =>
      a.title.toLowerCase().contains('ai') ||
      (a.description?.toLowerCase().contains('ai') ?? false)
    ).toList();

    print("\n🤖 TÌM THẤY ${aiArticles.length} BÀI VỀ AI:");
    for (int i = 0; i < aiArticles.length; i++) {
      print("${i + 1}. [${aiArticles[i].source}] ${aiArticles[i].title}");
    }

    // Kiểm tra độ tương đồng giữa các bài về AI
    if (aiArticles.length >= 2) {
      print("\n🔍 KIỂM TRA ĐỘ TƯƠNG ĐỒNG:\n");
      for (int i = 0; i < aiArticles.length; i++) {
        for (int j = i + 1; j < aiArticles.length; j++) {
          final similarity = ContentDeduplication.calculateSimilarity(
            aiArticles[i],
            aiArticles[j]
          );
          print("📊 Độ tương đồng giữa:");
          print("   📰 [${aiArticles[i].source}] ${aiArticles[i].title}");
          print("   📰 [${aiArticles[j].source}] ${aiArticles[j].title}");
          print("   🎯 Kết quả: ${(similarity * 100).toStringAsFixed(1)}%");

          if (similarity >= ContentDeduplication.SIMILARITY_THRESHOLD) {
            print("   ✅ TRÙNG LẶP - Nên được lọc!");
          } else {
            print("   ❌ KHÔNG TRÙNG - Độ tương đồng thấp hơn ${(ContentDeduplication.SIMILARITY_THRESHOLD * 100).toStringAsFixed(0)}%");
          }
          print("");
        }
      }
    }

    // Test lọc trùng lặp
    print("\n🧪 TEST LỌC TRÙNG LẶP:");
    print("📊 Trước khi lọc: ${articles.length} bài");
    final uniqueArticles = ContentDeduplication.removeDuplicates(articles);
    print("✅ Sau khi lọc: ${uniqueArticles.length} bài");
    print("🗑️ Đã loại bỏ: ${articles.length - uniqueArticles.length} bài trùng\n");
  }, timeout: const Timeout(Duration(seconds: 30)));
}

