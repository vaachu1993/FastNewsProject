import 'package:flutter_test/flutter_test.dart';
import 'package:fastnews/models/article_model.dart';
import 'package:fastnews/utils/content_deduplication.dart';

void main() {
  test('Test lọc bài viết trùng lặp với ngưỡng 55%', () {
    print("\n🧪 === TEST BÀI VIẾT TRÙNG LẶP ===\n");

    final article1 = ArticleModel(
      title: 'Bão số 10 đổ bộ vào miền Trung, gió giật cấp 12',
      description:
          'Bão Molave là cơn bão mạnh nhất năm 2024 đã đổ bộ vào các tỉnh miền Trung vào sáng nay với sức gió mạnh cấp 12, giật cấp 15. Nhiều khu vực bị ảnh hưởng nghiêm trọng với mưa lớn và gió mạnh.',
      source: 'VNExpress',
      link: 'https://vnexpress.net/bao-1',
      imageUrl: 'https://example.com/1.jpg',
      time: '2024-01-01',
    );

    final article2 = ArticleModel(
      title: 'Siêu bão Molave tiến vào miền Trung với sức gió mạnh',
      description:
          'Cơn bão mạnh nhất trong năm 2024, bão Molave, đã vào các tỉnh miền Trung sáng nay. Sức gió đạt cấp 12, giật cấp 15. Rất nhiều khu vực chịu ảnh hưởng nặng nề với mưa to và gió lớn.',
      source: 'Tuổi Trẻ',
      link: 'https://tuoitre.vn/bao-2',
      imageUrl: 'https://example.com/2.jpg',
      time: '2024-01-01',
    );

    final article3 = ArticleModel(
      title: 'Giải vô địch bóng đá châu Âu 2024 khởi tranh',
      description:
          'Giải đấu lớn nhất châu lục sẽ chính thức bắt đầu vào tháng 6 năm 2024 với sự tham gia của 24 đội tuyển quốc gia hàng đầu.',
      source: 'Thanh Niên',
      link: 'https://thanhnien.vn/bongda-3',
      imageUrl: 'https://example.com/3.jpg',
      time: '2024-01-01',
    );

    print("📰 Bài viết 1: [${article1.source}] ${article1.title}");
    print("📰 Bài viết 2: [${article2.source}] ${article2.title}");
    print("📰 Bài viết 3: [${article3.source}] ${article3.title}\n");

    // Tính độ tương đồng
    final similarity = ContentDeduplication.calculateSimilarity(article1, article2);
    print("🔍 Độ tương đồng giữa bài 1 và 2: ${(similarity * 100).toStringAsFixed(1)}%");
    print("🎯 Ngưỡng lọc hiện tại: ${(ContentDeduplication.SIMILARITY_THRESHOLD * 100).toStringAsFixed(0)}%\n");

    // Test lọc trùng lặp
    final articles = [article1, article2, article3];
    print("📊 Trước khi lọc: ${articles.length} bài viết");

    final unique = ContentDeduplication.removeDuplicates(articles);

    print("\n✅ Sau khi lọc: ${unique.length} bài viết");
    print("🗑️ Đã loại bỏ: ${articles.length - unique.length} bài viết\n");

    // Với ngưỡng 55%, 2 bài về bão (59.6% tương đồng) nên bị merge
    expect(unique.length, equals(2), reason: 'Nên còn 2 bài: 1 bài về bão (đã gộp) + 1 bài về bóng đá');

    print("✅ TEST PASS: Hệ thống đã lọc thành công ${articles.length - unique.length} bài trùng lặp!");
  });
}

