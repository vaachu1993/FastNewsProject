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
  List<String> userFavoriteTopics = [];
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
    _initializeData();

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  // Initialize data in correct order
  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    // Load user data and favorite topics FIRST
    await _loadUserData();
    await _loadUserFavoriteTopics();

    // Then load news based on favorite topics
    await _loadNews(isInitial: true);
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
      print('✅ Loaded user favorite topics: $topics');
      setState(() {
        userFavoriteTopics = topics;
      });
      if (topics.isNotEmpty) {
        print('📰 User has favorite topics - will filter news accordingly');
      } else {
        print('⚠️ No favorite topics found - will show all news');
      }
    } catch (e) {
      print('❌ Error loading user favorite topics: $e');
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

    List<ArticleModel> news;

    // If user has no favorite topics, show all news
    if (userFavoriteTopics.isEmpty) {
      print('📋 No favorite topics - loading all news for category: $category');
      news = (category == 'Tất cả')
          ? await RssService.fetchRandomNews()
          : await RssService.fetchNewsByCategory(category);
    } else {
      print('💖 User has favorite topics: $userFavoriteTopics');
      // Filter news based on favorite topics - ONLY show articles from favorite topics
      if (category == 'Tất cả') {
        print('📰 Loading news from ALL favorite topics');
        // Load news from all favorite topics only
        List<ArticleModel> allNews = [];
        for (String topic in userFavoriteTopics) {
          print('  - Fetching news for: $topic');
          final topicNews = await RssService.fetchNewsByCategory(topic);
          print('  - Got ${topicNews.length} articles for $topic');
          allNews.addAll(topicNews);
        }
        // Shuffle to mix different topics
        allNews.shuffle();
        news = allNews;
        print('✅ Total articles from favorite topics: ${news.length}');
      } else {
        // Only load news if the selected category is in favorite topics
        if (userFavoriteTopics.contains(category)) {
          print('✅ Category "$category" is in favorites - loading news');
          news = await RssService.fetchNewsByCategory(category);
        } else {
          print('⚠️ Category "$category" is NOT in favorites - showing empty list');
          // If selected category is not in favorites, show empty list
          news = [];
        }
      }
    }

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
                          child: Builder(
                            builder: (context) {
                              // Get filtered categories based on user's favorite topics
                              List<String> displayCategories;
                              if (userFavoriteTopics.isEmpty) {
                                displayCategories = categories;
                              } else {
                                displayCategories = ['Tất cả', ...userFavoriteTopics];
                              }

                              return ListView.builder(
                                controller: _categoryScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: displayCategories.length,
                                itemBuilder: (context, index) {
                                  final categoryIndex = userFavoriteTopics.isEmpty
                                      ? index
                                      : categories.indexOf(displayCategories[index]);
                                  final bool isSelected = selectedCategory == categoryIndex;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => selectedCategory = categoryIndex);
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
                                        child: Text(_translateCategory(displayCategories[index], currentLanguage)),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),



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
                          child: latestNews.isEmpty
                              ? Container(
                                  key: const ValueKey<String>('empty'),
                                  height: 320,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF2A2740)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.article_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        loc.translate('no_articles_in_category'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        loc.translate('select_favorite_topics_hint'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(
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
        return '🏛️';
      case 'Công nghệ':
        return '💻';
      case 'Kinh doanh':
        return '💼';
      case 'Thể thao':
        return '⚽';
      case 'Sức khỏe':
        return '❤️';
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
