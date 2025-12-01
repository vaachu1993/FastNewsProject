import '../models/article_model.dart';

/// Utility class for detecting and removing duplicate articles based on content similarity
class ContentDeduplication {
  /// Ngưỡng độ tương đồng để coi là trùng lặp (0.0 - 1.0)
  /// 0.7 = 70% tương đồng
  static const double SIMILARITY_THRESHOLD = 0.70;

  /// Loại bỏ các bài viết trùng lặp dựa trên độ tương đồng nội dung
  /// [threshold] - Ngưỡng độ tương đồng (mặc định 0.70 = 70%)
  static List<ArticleModel> removeDuplicates(
    List<ArticleModel> articles, {
    double? threshold,
  }) {
    if (articles.length <= 1) return articles;

    final similarityThreshold = threshold ?? SIMILARITY_THRESHOLD;
    List<ArticleModel> uniqueArticles = [];
    Set<int> processedIndices = {};

    for (int i = 0; i < articles.length; i++) {
      if (processedIndices.contains(i)) continue;

      ArticleModel currentArticle = articles[i];
      List<ArticleModel> similarArticles = [currentArticle];

      // Tìm tất cả bài viết tương tự với bài hiện tại
      for (int j = i + 1; j < articles.length; j++) {
        if (processedIndices.contains(j)) continue;

        double similarity = calculateSimilarity(
          currentArticle,
          articles[j],
        );

        if (similarity >= similarityThreshold) {
          similarArticles.add(articles[j]);
          processedIndices.add(j);
        }
      }

      // Chọn bài viết tốt nhất từ nhóm tương tự
      ArticleModel bestArticle = _selectBestArticle(similarArticles);
      uniqueArticles.add(bestArticle);
      processedIndices.add(i);
    }

    return uniqueArticles;
  }

  /// Tính toán độ tương đồng giữa 2 bài viết (0.0 - 1.0)
  static double calculateSimilarity(ArticleModel article1, ArticleModel article2) {
    // Nếu cùng link => 100% trùng
    if (article1.link == article2.link) return 1.0;

    // Tính độ tương đồng tiêu đề (30% trọng số)
    double titleSimilarity = _calculateTextSimilarity(
      _normalizeText(article1.title),
      _normalizeText(article2.title),
    );

    // Tính độ tương đồng mô tả (70% trọng số)
    double descriptionSimilarity = 0.0;
    if (article1.description != null && article2.description != null) {
      descriptionSimilarity = _calculateTextSimilarity(
        _normalizeText(article1.description!),
        _normalizeText(article2.description!),
      );
    }

    // Trọng số: 30% tiêu đề, 70% nội dung
    return (titleSimilarity * 0.3) + (descriptionSimilarity * 0.7);
  }

  /// Chuẩn hóa văn bản để so sánh
  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Loại bỏ ký tự đặc biệt
        .replaceAll(RegExp(r'\s+'), ' ') // Chuẩn hóa khoảng trắng
        .trim();
  }

  /// Tính độ tương đồng giữa 2 chuỗi văn bản bằng Jaccard Similarity
  /// (số từ chung / tổng số từ unique)
  static double _calculateTextSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    Set<String> words1 = text1.split(' ').toSet();
    Set<String> words2 = text2.split(' ').toSet();

    if (words1.isEmpty && words2.isEmpty) return 0.0;

    // Jaccard similarity: intersection / union
    int intersection = words1.intersection(words2).length;
    int union = words1.union(words2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  /// Sử dụng thuật toán Levenshtein Distance để tính độ tương đồng chi tiết hơn
  /// (Thuật toán thay thế - có thể dùng thay cho Jaccard Similarity nếu cần độ chính xác cao hơn)
  // ignore: unused_element
  static double _levenshteinSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int distance = _levenshteinDistance(s1, s2);
    int maxLength = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLength);
  }

  /// Tính khoảng cách Levenshtein giữa 2 chuỗi
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Chọn bài viết tốt nhất từ danh sách các bài tương tự
  /// Ưu tiên: Nội dung dài hơn, ảnh có sẵn, nguồn uy tín
  static ArticleModel _selectBestArticle(List<ArticleModel> articles) {
    if (articles.length == 1) return articles.first;

    ArticleModel bestArticle = articles.first;
    int bestScore = _calculateArticleQualityScore(bestArticle);

    for (int i = 1; i < articles.length; i++) {
      int currentScore = _calculateArticleQualityScore(articles[i]);
      if (currentScore > bestScore) {
        bestScore = currentScore;
        bestArticle = articles[i];
      }
    }

    return bestArticle;
  }

  /// Tính điểm chất lượng của bài viết
  static int _calculateArticleQualityScore(ArticleModel article) {
    int score = 0;

    // Điểm cho độ dài description (+1 điểm mỗi 100 ký tự, max 10)
    if (article.description != null) {
      int descLength = article.description!.length;
      score += (descLength ~/ 100).clamp(0, 10);
    }

    // Điểm cho việc có ảnh (+5 điểm)
    if (article.imageUrl.isNotEmpty) {
      score += 5;
    }

    // Điểm ưu tiên nguồn tin (+3 điểm cho nguồn uy tín)
    if (article.source == 'VNExpress') {
      score += 3;
    } else if (article.source == 'Tuổi Trẻ') {
      score += 2;
    } else if (article.source == 'Thanh Niên') {
      score += 2;
    }

    // Điểm cho tiêu đề dài, chi tiết hơn (+1 điểm mỗi 20 ký tự, max 5)
    score += (article.title.length ~/ 20).clamp(0, 5);

    return score;
  }

  /// Kiểm tra 2 bài viết có trùng lặp không
  static bool isDuplicate(ArticleModel article1, ArticleModel article2) {
    return calculateSimilarity(article1, article2) >= SIMILARITY_THRESHOLD;
  }

  /// Nhóm các bài viết tương tự với nhau
  static List<List<ArticleModel>> groupSimilarArticles(List<ArticleModel> articles) {
    if (articles.isEmpty) return [];

    List<List<ArticleModel>> groups = [];
    Set<int> processedIndices = {};

    for (int i = 0; i < articles.length; i++) {
      if (processedIndices.contains(i)) continue;

      List<ArticleModel> group = [articles[i]];
      processedIndices.add(i);

      for (int j = i + 1; j < articles.length; j++) {
        if (processedIndices.contains(j)) continue;

        if (isDuplicate(articles[i], articles[j])) {
          group.add(articles[j]);
          processedIndices.add(j);
        }
      }

      groups.add(group);
    }

    return groups;
  }
}

