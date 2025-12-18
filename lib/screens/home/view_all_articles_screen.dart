import 'package:flutter/material.dart';
import '../../models/article_model.dart';
import '../../widgets/article_card_horizontal.dart';
import '../../services/rss_service.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/localization_provider.dart';

class ViewAllArticlesScreen extends StatefulWidget {
  final String category;
  final String title;
  final List<String>? favoriteTopics; // Để filter theo favorite topics nếu cần

  const ViewAllArticlesScreen({
    super.key,
    required this.category,
    required this.title,
    this.favoriteTopics,
  });

  @override
  State<ViewAllArticlesScreen> createState() => _ViewAllArticlesScreenState();
}

class _ViewAllArticlesScreenState extends State<ViewAllArticlesScreen> {
  List<ArticleModel> articles = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  static const int articlesPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!isLoadingMore) {
        _loadMoreArticles();
      }
    }
  }

  Future<void> _loadArticles() async {
    setState(() => isLoading = true);

    try {
      List<ArticleModel> loadedArticles;

      // Nếu có favorite topics và category là "Tất cả", load theo topics
      if (widget.favoriteTopics != null &&
          widget.favoriteTopics!.isNotEmpty &&
          widget.category == 'Tất cả') {
        // Load song song tất cả favorite topics
        final futures = widget.favoriteTopics!.map((topic) {
          return RssService.fetchNewsByCategory(topic);
        }).toList();

        final results = await Future.wait(futures);
        loadedArticles = results.expand((list) => list).toList();
        loadedArticles.shuffle();
      } else if (widget.category == 'Tất cả') {
        // Load tất cả tin tức
        loadedArticles = await RssService.fetchRandomNews();
      } else {
        // Load theo category cụ thể
        loadedArticles = await RssService.fetchNewsByCategory(widget.category);
      }

      setState(() {
        articles = loadedArticles;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        final localizationProvider = LocalizationProvider.of(context);
        final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentLanguage == 'vi'
              ? 'Lỗi tải tin tức: $e'
              : 'Error loading news: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreArticles() async {
    if (isLoadingMore) return;

    setState(() => isLoadingMore = true);

    try {
      // Giả lập load thêm (có thể cải thiện bằng pagination thực tế)
      await Future.delayed(const Duration(seconds: 1));

      List<ArticleModel> moreArticles;
      if (widget.category == 'Tất cả') {
        moreArticles = await RssService.fetchRandomNews();
      } else {
        moreArticles = await RssService.fetchNewsByCategory(widget.category);
      }

      // Loại bỏ các bài đã có (dựa trên link)
      final existingLinks = articles.map((a) => a.link).toSet();
      moreArticles.removeWhere((article) => existingLinks.contains(article.link));

      setState(() {
        articles.addAll(moreArticles);
        isLoadingMore = false;
        currentPage++;
      });
    } catch (e) {
      setState(() => isLoadingMore = false);
    }
  }

  Future<void> _refreshArticles() async {
    currentPage = 1;
    await _loadArticles();
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
            onPressed: _refreshArticles,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : articles.isEmpty
              ? _buildEmptyState(loc)
              : RefreshIndicator(
                  onRefresh: _refreshArticles,
                  child: Column(
                    children: [
                      // Header với số lượng bài viết
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2740)
                              : Colors.grey.shade100,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentLanguage == 'vi'
                                  ? '${articles.length} bài viết'
                                  : '${articles.length} articles',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const Spacer(),
                            if (widget.favoriteTopics != null &&
                                widget.favoriteTopics!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentLanguage == 'vi'
                                          ? 'Đã lọc'
                                          : 'Filtered',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Danh sách bài viết
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: articles.length + (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == articles.length) {
                              // Loading indicator ở cuối
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const CircularProgressIndicator(
                                        color: Colors.green,
                                        strokeWidth: 2,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        currentLanguage == 'vi'
                                            ? 'Đang tải thêm...'
                                            : 'Loading more...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Animate từng item khi load
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 300 + (index % 5) * 50,
                              ),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ArticleCardHorizontal(
                                  article: articles[index],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('no_articles_in_category'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('select_favorite_topics_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshArticles,
              icon: const Icon(Icons.refresh),
              label: Text(loc.translate('refresh')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

