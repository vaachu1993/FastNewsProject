import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../widgets/article_card_horizontal.dart';
import '../services/rss_service.dart';

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

  final List<String> tags = RssService.getCategories();

  @override
  void initState() {
    super.initState();
    _loadNews(isInitial: true);
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

  void _searchArticles(String query) {
    setState(() {
      searchQuery = query;
      filteredArticles = RssService.searchArticles(articles, query);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tin tức...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchArticles('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _searchArticles,
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
                                  : Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tags[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.green,
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
                            ? 'Tin tức ${tags[selectedTag]}'
                            : 'Kết quả tìm kiếm',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${filteredArticles.length} bài viết',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedOpacity(
                    opacity: isLoadingMore ? 0.5 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: filteredArticles.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          searchQuery.isEmpty
                              ? 'Không có tin tức nào'
                              : 'Không tìm thấy kết quả cho "$searchQuery"',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
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
