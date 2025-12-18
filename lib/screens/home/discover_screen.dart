import 'package:flutter/material.dart';
import '../../models/article_model.dart';
import '../../widgets/article_card_horizontal.dart';
import '../../services/rss_service.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/localization_provider.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int selectedTag = 0;
  bool isLoading = true;
  bool isLoadingMore = false; // Loading khi chuyển tag
  List<ArticleModel> articles = [];
  List<ArticleModel> filteredArticles = [];
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Track language to reload on change
  String? _previousLanguage;

  final List<String> tags = RssService.getCategories();

  @override
  void initState() {
    super.initState();
    _loadNews(isInitial: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check for language change
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';

    if (_previousLanguage != null && _previousLanguage != currentLanguage) {
      // Language changed, reload data
      _previousLanguage = currentLanguage;
      Future.microtask(() {
        if (mounted) {
          setState(() {
            selectedTag = 0;
            isLoading = true;
          });
          _loadNews(isInitial: true);
        }
      });
    } else if (_previousLanguage == null) {
      _previousLanguage = currentLanguage;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool isInitial = false}) async {
    // Nếu là lần đầu, hiển thị loading toàn màn hình
    // Nếu chuyển tag, chỉ hiển thị loading nhỏ và giữ lại UI cũ
    if (isInitial || articles.isEmpty) {
      setState(() => isLoading = true);
    } else {
      setState(() => isLoadingMore = true);
    }

    final category = tags[selectedTag];
    final news = await RssService.fetchNewsByCategory(category);

    setState(() {
      articles = news;
      filteredArticles = news;
      searchQuery = '';
      isLoading = false;
      isLoadingMore = false;
    });
  }

  Future<void> _searchArticles(String query) async {
    setState(() {
      searchQuery = query;
    });

    // Nếu đang ở tab "Tất cả" hoặc "Mới nhất" và có search query
    // → Tìm trong TẤT CẢ các danh mục
    final currentCategory = tags[selectedTag];
    if (query.trim().isNotEmpty &&
        (currentCategory == 'Tất cả' || currentCategory == 'Mới nhất')) {

      setState(() => isLoadingMore = true);

      // Load tất cả bài viết từ TẤT CẢ các categories
      List<ArticleModel> allArticles = [];
      final allCategories = RssService.getCategories();

      // Load song song tất cả categories
      final futures = allCategories
          .where((cat) => cat != 'Tất cả' && cat != 'Mới nhất') // Bỏ qua 2 category tổng hợp
          .map((category) => RssService.fetchNewsByCategory(category));

      final results = await Future.wait(futures);
      for (var categoryArticles in results) {
        allArticles.addAll(categoryArticles);
      }

      // Remove duplicates by ID
      final uniqueArticles = <String, ArticleModel>{};
      for (var article in allArticles) {
        uniqueArticles[article.id] = article;
      }
      allArticles = uniqueArticles.values.toList();

      // Sort by time (newest first)
      allArticles.sort((a, b) => b.time.compareTo(a.time));

      // Search trong tất cả bài viết
      final searchResults = RssService.searchArticles(allArticles, query);

      setState(() {
        filteredArticles = searchResults;
        isLoadingMore = false;
      });
    } else {
      // Tìm trong category hiện tại
      setState(() {
        filteredArticles = RssService.searchArticles(articles, query);
      });
    }
  }

  String _translateCategory(String category, String currentLanguage) {
    if (currentLanguage == 'en') {
      switch (category) {
        case 'Tất cả':
          return 'All';
        case 'Mới nhất':
          return 'Latest';
        case 'Chính trị':
          return 'Politics';
        case 'Kinh doanh':
          return 'Business';
        case 'Công nghệ':
          return 'Technology';
        case 'Thể thao':
          return 'Sports';
        case 'Giải trí':
          return 'Entertainment';
        case 'Sức khỏe':
          return 'Health';
        case 'Khoa học':
          return 'Science';
        case 'Thế giới':
          return 'World';
        case 'Đời sống':
          return 'Lifestyle';
        default:
          return category;
      }
    }
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          loc.discover,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadNews,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: Theme.of(context).brightness == Brightness.light
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: currentLanguage == 'vi'
                            ? 'Tìm kiếm tin tức...'
                            : 'Search news...',
                        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchArticles('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2740)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: Theme.of(context).brightness == Brightness.light
                              ? BorderSide(color: Colors.grey.shade300, width: 1)
                              : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: Theme.of(context).brightness == Brightness.light
                              ? BorderSide(color: Colors.grey.shade300, width: 1)
                              : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: _searchArticles,
                    ),
                  ),
                  // Info text when searching in "Tất cả" or "Mới nhất"
                  if (searchQuery.isNotEmpty &&
                      (tags[selectedTag] == 'Tất cả' || tags[selectedTag] == 'Mới nhất'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentLanguage == 'vi'
                                ? 'Đang tìm trong tất cả danh mục...'
                                : 'Searching across all categories...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = selectedTag == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedTag = index);
                            _loadNews();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF2A2740)
                                      : Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _translateCategory(tags[index], currentLanguage),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        searchQuery.isEmpty
                            ? (currentLanguage == 'vi'
                                ? 'Tin tức ${_translateCategory(tags[selectedTag], currentLanguage)}'
                                : '${_translateCategory(tags[selectedTag], currentLanguage)} News')
                            : (currentLanguage == 'vi'
                                ? 'Kết quả tìm kiếm'
                                : 'Search Results'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        currentLanguage == 'vi'
                            ? '${filteredArticles.length} bài viết'
                            : '${filteredArticles.length} articles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Loading indicator when searching
                  if (isLoadingMore && searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              currentLanguage == 'vi'
                                  ? 'Đang tìm kiếm...'
                                  : 'Searching...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  AnimatedOpacity(
                    opacity: isLoadingMore ? 0.5 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: filteredArticles.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          searchQuery.isEmpty
                              ? (currentLanguage == 'vi'
                                  ? 'Không có tin tức nào'
                                  : 'No articles')
                              : (currentLanguage == 'vi'
                                  ? 'Không tìm thấy kết quả cho "$searchQuery"'
                                  : 'No results found for "$searchQuery"'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                        : Column(
                      children: filteredArticles.map((a) => ArticleCardHorizontal(article: a)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading indicator nhỏ ở góc khi đang load thêm
          if (isLoadingMore)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

