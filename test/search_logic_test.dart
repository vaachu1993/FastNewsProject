import 'package:flutter_test/flutter_test.dart';
import 'package:fastnews/models/article_model.dart';
import 'package:fastnews/services/rss_service.dart';

void main() {
  group('Search Logic Tests', () {
    // Sample articles for testing
    final testArticles = [
      ArticleModel(
        title: 'Công nghệ AI đang thay đổi thế giới',
        source: 'VNExpress',
        time: '2024-01-01',
        imageUrl: 'https://example.com/1.jpg',
        link: 'https://example.com/1',
        description: 'ChatGPT và các mô hình AI đang cách mạng hóa nhiều ngành công nghiệp',
      ),
      ArticleModel(
        title: 'Bóng đá Việt Nam vô địch SEA Games',
        source: 'Tuổi Trẻ',
        time: '2024-01-02',
        imageUrl: 'https://example.com/2.jpg',
        link: 'https://example.com/2',
        description: 'Đội tuyển Việt Nam giành chiến thắng 3-0 trước Thái Lan',
      ),
      ArticleModel(
        title: 'Sức khỏe tinh thần trong đại dịch',
        source: 'Thanh Niên',
        time: '2024-01-03',
        imageUrl: 'https://example.com/3.jpg',
        link: 'https://example.com/3',
        description: 'COVID-19 ảnh hưởng nghiêm trọng đến sức khỏe tâm lý người dân',
      ),
      ArticleModel(
        title: 'Kinh tế Việt Nam tăng trưởng mạnh',
        source: 'VNExpress',
        time: '2024-01-04',
        imageUrl: 'https://example.com/4.jpg',
        link: 'https://example.com/4',
        description: 'GDP quý 1 đạt 6.5%, vượt kỳ vọng của các chuyên gia',
      ),
      ArticleModel(
        title: 'Startup công nghệ Việt gọi vốn thành công',
        source: 'Tuổi Trẻ',
        time: '2024-01-05',
        imageUrl: 'https://example.com/5.jpg',
        link: 'https://example.com/5',
        description: 'Startup về AI và machine learning nhận được 10 triệu USD',
      ),
    ];

    test('Test 1: Tìm trong title', () {
      final results = RssService.searchArticles(testArticles, 'bóng đá');
      expect(results.length, 1);
      expect(results[0].title.contains('Bóng đá'), true);
    });

    test('Test 2: Tìm trong description', () {
      final results = RssService.searchArticles(testArticles, 'ChatGPT');
      expect(results.length, 1);
      expect(results[0].description!.contains('ChatGPT'), true);
    });

    test('Test 3: Tìm theo source', () {
      final results = RssService.searchArticles(testArticles, 'VNExpress');
      expect(results.length, 2); // 2 bài từ VNExpress
      expect(results.every((a) => a.source == 'VNExpress'), true);
    });

    test('Test 4: Tìm nhiều từ khóa (AND logic)', () {
      final results = RssService.searchArticles(testArticles, 'công nghệ AI');
      expect(results.length, 2); // Bài 1 và bài 5 đều có "công nghệ" và "AI"
    });

    test('Test 5: Tìm không dấu', () {
      final results = RssService.searchArticles(testArticles, 'tuoi tre');
      expect(results.length, 2); // 2 bài từ "Tuổi Trẻ"
      expect(results.every((a) => a.source == 'Tuổi Trẻ'), true);
    });

    test('Test 6: Tìm với spaces thừa', () {
      final results = RssService.searchArticles(testArticles, '  công  nghệ  ');
      expect(results.length, 2); // Bài 1 và bài 5
    });

    test('Test 7: Query rỗng trả về tất cả', () {
      final results = RssService.searchArticles(testArticles, '');
      expect(results.length, 5);
    });

    test('Test 8: Query chỉ có spaces trả về tất cả', () {
      final results = RssService.searchArticles(testArticles, '   ');
      expect(results.length, 5);
    });

    test('Test 9: Không tìm thấy kết quả', () {
      final results = RssService.searchArticles(testArticles, 'xyz123');
      expect(results.length, 0);
    });

    test('Test 10: Case insensitive', () {
      final results = RssService.searchArticles(testArticles, 'CÔNG NGHỆ');
      expect(results.length, 2);
    });

    test('Test 11: Tìm kết hợp (keyword + source)', () {
      final results = RssService.searchArticles(testArticles, 'AI VNExpress');
      expect(results.length, 1); // Chỉ bài 1 có cả "AI" và "VNExpress"
      expect(results[0].title.contains('AI'), true);
      expect(results[0].source, 'VNExpress');
    });

    test('Test 12: Tìm với từ có dấu', () {
      final results = RssService.searchArticles(testArticles, 'Việt Nam');
      expect(results.length >= 2, true); // Có ít nhất 2 bài về Việt Nam
    });

    test('Test 13: Tìm không dấu khớp với có dấu', () {
      final results1 = RssService.searchArticles(testArticles, 'viet nam');
      final results2 = RssService.searchArticles(testArticles, 'Việt Nam');
      expect(results1.length, results2.length); // Cùng kết quả
    });

    test('Test 14: Tìm trong title và description đồng thời', () {
      final results = RssService.searchArticles(testArticles, 'COVID');
      expect(results.length, 1);
      expect(results[0].description!.contains('COVID'), true);
    });

    test('Test 15: Tìm tất cả bài về "công nghệ"', () {
      final results = RssService.searchArticles(testArticles, 'công nghệ');
      expect(results.length, 2); // Bài 1 và bài 5
    });
  });

  group('Vietnamese Tone Removal Tests', () {
    test('Test bỏ dấu các nguyên âm', () {
      // Note: _removeVietnameseTones is private, so we test indirectly
      final articles = [
        ArticleModel(
          title: 'Đại học Bách Khoa',
          source: 'Test',
          time: '2024-01-01',
          imageUrl: 'test.jpg',
          link: 'test.com',
        ),
      ];

      // Search without tones should find article with tones
      final results = RssService.searchArticles(articles, 'dai hoc bach khoa');
      expect(results.length, 1);
    });

    test('Test các dấu sắc, huyền, hỏi, ngã, nặng', () {
      final articles = [
        ArticleModel(
          title: 'Á Âu Ầu Ấu Ậu',
          source: 'Test',
          time: '2024-01-01',
          imageUrl: 'test.jpg',
          link: 'test.com',
        ),
      ];

      final results = RssService.searchArticles(articles, 'a au au au au');
      expect(results.length, 1);
    });

    test('Test chữ đ -> d', () {
      final articles = [
        ArticleModel(
          title: 'Đồng bằng sông Cửu Long',
          source: 'Test',
          time: '2024-01-01',
          imageUrl: 'test.jpg',
          link: 'test.com',
        ),
      ];

      final results = RssService.searchArticles(articles, 'dong bang');
      expect(results.length, 1);
    });
  });

  group('Performance Tests', () {
    test('Test với nhiều bài viết', () {
      // Tạo 1000 bài viết
      final largeArticleList = List.generate(1000, (index) => ArticleModel(
        title: 'Bài viết số $index về công nghệ',
        source: 'Source ${index % 3}',
        time: '2024-01-01',
        imageUrl: 'test.jpg',
        link: 'test.com/$index',
        description: 'Mô tả bài viết $index',
      ));

      final stopwatch = Stopwatch()..start();
      final results = RssService.searchArticles(largeArticleList, 'công nghệ');
      stopwatch.stop();

      print('⏱️ Search time for 1000 articles: ${stopwatch.elapsedMilliseconds}ms');
      expect(results.length, 1000); // Tất cả đều có "công nghệ"
      expect(stopwatch.elapsedMilliseconds < 100, true); // < 100ms
    });
  });
}

