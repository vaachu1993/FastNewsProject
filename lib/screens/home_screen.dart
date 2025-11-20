import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article_model.dart';
import '../widgets/article_card_horizontal.dart';
import '../services/rss_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_localizations.dart';
import '../widgets/localization_provider.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({super.key, this.onNavigateToProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  int selectedCategory = 0;
  bool isLoading = true;
  bool isLoadingMore = false;
  List<ArticleModel> latestNews = [];
  List<ArticleModel> favoriteTopicsNews = [];
  List<String> userFavoriteTopics = [];
  Map<String, int> topicArticleCounts = {};
  final ScrollController _categoryScrollController = ScrollController();

  // Add user data
  User? _currentUser;
  Map<String, dynamic>? _userData;

  // Track language to reload on change
  String? _previousLanguage;

  final List<String> categories = RssService.getCategories();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserFavoriteTopics();
    _loadNews(isInitial: true);

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        _loadUserData();
      }
    });
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
            selectedCategory = 0;
            isLoading = true;
          });
          _loadNews(isInitial: true);
          _loadFavoriteTopicsNews();
        }
      });
    } else if (_previousLanguage == null) {
      _previousLanguage = currentLanguage;
    }
  }

  Future<void> _loadUserData() async {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _userData = await _authService.getUserData(_currentUser!.uid);
      setState(() {});
    }
  }

  Future<void> _loadUserFavoriteTopics() async {
    try {
      final topics = await _firestoreService.getUserFavoriteTopics();
      setState(() {
        userFavoriteTopics = topics;
      });
      if (topics.isNotEmpty) {
        _loadFavoriteTopicsNews();
      }
    } catch (e) {
      print('Error loading user favorite topics: $e');
    }
  }

  Future<void> _loadFavoriteTopicsNews() async {
    try {
      List<ArticleModel> allNews = [];

      // Load news from each favorite topic
      for (String topic in userFavoriteTopics) {
        final news = await RssService.fetchNewsByCategory(topic);
        allNews.addAll(news.take(3)); // Take 3 articles from each topic
      }

      // Shuffle to mix different topics
      allNews.shuffle();

      setState(() {
        favoriteTopicsNews = allNews.take(10).toList();
      });
    } catch (e) {
      print('Error loading favorite topics news: $e');
    }
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool isInitial = false, bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        selectedCategory = 0;
        isLoading = true;
      });
      // Reload user data and favorite topics when refreshing
      await _loadUserData();
      await _loadUserFavoriteTopics();
    } else if (isInitial || latestNews.isEmpty) {
      setState(() => isLoading = true);
    } else {
      setState(() => isLoadingMore = true);
    }

    final category = categories[selectedCategory];

    final news = (category == 'Tất cả')
        ? await RssService.fetchRandomNews()
        : await RssService.fetchNewsByCategory(category);

    setState(() {
      latestNews = news;
      isLoading = false;
      isLoadingMore = false;
    });
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              // Find the root Scaffold (MainScreen's Scaffold)
              final scaffoldState = context.findRootAncestorStateOfType<ScaffoldState>();
              scaffoldState?.openDrawer();
            },
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.newspaper,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FastNews',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        actions: [
          Icon(Icons.notifications_outlined, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              // Navigate to profile screen using callback
              widget.onNavigateToProfile?.call();
            },
            child: CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFF5A7D3C),
              backgroundImage: (_userData?['photoURL'] != null && _userData!['photoURL'].toString().isNotEmpty) ||
                      (_currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty)
                  ? NetworkImage(_userData?['photoURL'] ?? _currentUser?.photoURL ?? '')
                  : null,
              child: (_userData?['photoURL'] == null || _userData!['photoURL'].toString().isEmpty) &&
                      (_currentUser?.photoURL == null || _currentUser!.photoURL!.isEmpty)
                  ? Text(
                      (_userData?['displayName'] ?? _currentUser?.displayName ?? _userData?['email'] ?? _currentUser?.email ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => _loadNews(isRefresh: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề Tin nổi bật
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.translate('featured_news'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                loc.translate('view_all'),
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),

                        // Danh mục
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            controller: _categoryScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final bool isSelected = selectedCategory == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => selectedCategory = index);
                                  _loadNews();
                                  // Scroll mượt đến category được chọn
                                  _categoryScrollController.animateTo(
                                    index * 100.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  margin: const EdgeInsets.only(right: 10, bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.green
                                        : Theme.of(context).brightness == Brightness.dark
                                            ? const Color(0xFF2A2740)
                                            : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.green.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).textTheme.bodyLarge?.color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    child: Text(_translateCategory(categories[index], currentLanguage)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Favorite Topics Section (if user has selected topics)
                        if (userFavoriteTopics.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    loc.favoriteTopics,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: _loadFavoriteTopicsNews,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.green,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Display selected topics as chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: userFavoriteTopics.map((topic) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getTopicIcon(topic),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _translateCategory(topic, currentLanguage),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Favorite topics news list
                          if (favoriteTopicsNews.isNotEmpty)
                            SizedBox(
                              height: 320,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: favoriteTopicsNews.length.clamp(0, 10),
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 300,
                                    margin: const EdgeInsets.only(right: 14),
                                    child: ArticleCardHorizontal(
                                      article: favoriteTopicsNews[index],
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],


                        // Danh sách tin nổi bật (trượt ngang) với AnimatedSwitcher
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: SizedBox(
                            key: ValueKey<int>(selectedCategory),
                            height: 320,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: latestNews.length.clamp(0, 5),
                              itemBuilder: (context, index) {
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 300 + (index * 50)),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(20 * (1 - value), 0),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 300,
                                    margin: const EdgeInsets.only(right: 14),
                                    child: ArticleCardHorizontal(
                                        article: latestNews[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tin toàn cầu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.translate('global_news'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                loc.translate('view_all'),
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Danh sách tin dọc với animation
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            key: ValueKey<int>(selectedCategory + 1000),
                            children: latestNews
                                .skip(5)
                                .take(5)
                                .map((a) => ArticleCardHorizontal(article: a))
                                .toList(),
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

  String _getTopicIcon(String topic) {
    switch (topic) {
      case 'Chính trị':
        return '🏛';
      case 'Công nghệ':
        return '💻';
      case 'Kinh doanh':
        return '💼';
      case 'Thể thao':
        return '⚽';
      case 'Sức khỏe':
        return '❤';
      case 'Đời sống':
        return '🎭';
      default:
        return '📰';
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
    return category; // Return original if Vietnamese
  }
}
