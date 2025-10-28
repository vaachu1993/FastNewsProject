import 'package:flutter/material.dart';
import '../models/article_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> with TickerProviderStateMixin {
  String? fullContent;
  bool isLoadingContent = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Khởi tạo animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Bắt đầu animation
    _fadeController.forward();
    _scaleController.forward();

    _fetchFullContent();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Fetch nội dung đầy đủ từ website gốc
  Future<void> _fetchFullContent({bool isRefresh = false}) async {
    if (!isRefresh && fullContent != null) return; // Đã có nội dung rồi

    setState(() {
      isLoadingContent = true;
    });

    // Animation cho loading
    if (isRefresh) {
      _scaleController.reset();
      _scaleController.forward();
    }

    try {
      final response = await http.get(
        Uri.parse(widget.article.link),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'vi-VN,vi;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 15)); // Timeout 15 giây

      if (response.statusCode == 200) {
        // Parse HTML content với encoding phù hợp
        final document = html_parser.parse(response.body);
        String extractedContent = _extractContentFromHtml(document);

        // Delay nhỏ để animation mượt hơn
        await Future.delayed(const Duration(milliseconds: 300));

        setState(() {
          fullContent = extractedContent;
          isLoadingContent = false;
        });

        // Show success animation nếu là refresh
        if (isRefresh) {
          _showSuccessSnackBar();
        }
      } else {
        setState(() {
          fullContent = 'Không thể tải nội dung từ nguồn gốc (Lỗi ${response.statusCode}). Vui lòng nhấn "Đọc bài gốc" để xem toàn bộ bài viết.';
          isLoadingContent = false;
        });
      }
    } catch (e) {
      print('Error fetching content: $e');
      setState(() {
        fullContent = 'Không thể tải nội dung từ nguồn gốc. Vui lòng kiểm tra kết nối mạng và nhấn "Đọc bài gốc" để xem toàn bộ bài viết.';
        isLoadingContent = false;
      });

      if (isRefresh) {
        _showErrorSnackBar();
      }
    }
  }

  /// Hiển thị snackbar thành công
  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Đã cập nhật nội dung mới nhất'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Hiển thị snackbar lỗi
  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Không thể cập nhật nội dung'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.white,
          onPressed: () => _fetchFullContent(isRefresh: true),
        ),
      ),
    );
  }

  /// Extract nội dung chính từ HTML document
  String _extractContentFromHtml(dom.Document document) {
    // Loại bỏ các thẻ không cần thiết
    document.querySelectorAll('script, style, nav, header, footer, aside, .advertisement, .ads, .social-share, .related-articles, .box-tin-lien-quan, .box-category-footer').forEach((element) {
      element.remove();
    });

    List<String> contentParts = [];

    // Thử các selector phổ biến cho nội dung bài viết từ các trang web Việt Nam
    List<String> contentSelectors = [
      // VnExpress
      '.fck_detail p',
      '.Normal p',

      // Tuổi Trẻ
      '.detail-content p',
      '.article-content p',

      // Thanh Niên
      '.details__content p',
      '.content p',

      // Dân Trí
      '.dt-news__content p',

      // 24h
      '.edittor-content p',

      // Zing News
      '.the-article-body p',

      // General selectors
      'article p',
      '.post-content p',
      '.entry-content p',
      '.news-content p',
      '.article-body p',
      '.story-content p',
      '.main-content p',
      '.content-detail p',
      '.news-detail p',
      'p', // fallback
    ];

    for (String selector in contentSelectors) {
      var paragraphs = document.querySelectorAll(selector);
      if (paragraphs.isNotEmpty) {
        for (var p in paragraphs) {
          String text = p.text.trim();
          // Lọc bỏ các đoạn quảng cáo hoặc không liên quan
          if (text.isNotEmpty &&
              text.length > 30 &&
              !text.toLowerCase().contains('quảng cáo') &&
              !text.toLowerCase().contains('advertisement') &&
              !text.toLowerCase().contains('xem thêm') &&
              !text.toLowerCase().contains('theo vnexpress') &&
              !text.toLowerCase().contains('theo tuổi trẻ') &&
              !text.toLowerCase().contains('theo thanh niên')) {
            contentParts.add(text);
          }
        }
        if (contentParts.length >= 3) break; // Tìm đủ nội dung rồi thì dừng
      }
    }

    // Nếu không tìm thấy đủ nội dung qua selector, thử lấy từ các thẻ div có class cụ thể
    if (contentParts.length < 3) {
      List<String> divSelectors = [
        '.fck_detail div',
        '.detail-content div',
        '.details__content div',
        '.dt-news__content div',
        '.edittor-content div',
        '.the-article-body div',
        '.content-detail div',
        '.news-detail div',
      ];

      for (String selector in divSelectors) {
        var divs = document.querySelectorAll(selector);
        for (var div in divs) {
          String text = div.text.trim();
          if (text.length > 80 && text.length < 1500 &&
              !text.toLowerCase().contains('quảng cáo') &&
              !text.toLowerCase().contains('xem thêm')) {
            contentParts.add(text);
            if (contentParts.length >= 5) break;
          }
        }
        if (contentParts.length >= 5) break;
      }
    }

    // Làm sạch và format nội dung
    String content = contentParts.take(8).join('\n\n'); // Lấy tối đa 8 đoạn để có nhiều nội dung hơn
    content = content
        .replaceAll(RegExp(r'\s+'), ' ') // Loại bỏ khoảng trắng thừa
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Chuẩn hóa xuống dòng
        .replaceAll(RegExp(r'\.{3,}'), '...') // Chuẩn hóa dấu ba chấm
        .trim();

    return content.isNotEmpty ? content : 'Không thể tải nội dung đầy đủ từ nguồn gốc. Vui lòng nhấn "Đọc bài gốc" để xem toàn bộ bài viết.';
  }
  String _stripHtmlTags(String htmlText) {
    String text = htmlText
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n\n+'), '\n\n')
        .trim();
    return text;
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng nội dung đã fetch được hoặc fallback về description
    String displayContent = '';

    if (fullContent != null && fullContent!.isNotEmpty) {
      displayContent = fullContent!;
    } else if (widget.article.description != null && widget.article.description!.isNotEmpty) {
      displayContent = _stripHtmlTags(widget.article.description!);
    } else {
      displayContent = 'Đang tải nội dung bài viết...';
    }

    // Nếu đang loading và chưa có nội dung đầy đủ
    if (isLoadingContent && (fullContent == null || fullContent!.isEmpty)) {
      if (widget.article.description != null && widget.article.description!.isNotEmpty) {
        displayContent = _stripHtmlTags(widget.article.description!) + '\n\n⏳ Đang tải thêm nội dung...';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FastNews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black87),
            onPressed: () {
              // TODO: Thêm vào bookmark
            },
          ),
          IconButton(
            icon: isLoadingContent
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.black87),
            onPressed: isLoadingContent ? null : () => _fetchFullContent(isRefresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {
              // TODO: Chia sẻ bài viết
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              // TODO: Menu khác
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchFullContent(isRefresh: true),
        color: Colors.green,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh bài viết với hero animation
                  Hero(
                    tag: 'article_image_${widget.article.link}',
                    child: Image.network(
                      widget.article.imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 80, color: Colors.grey),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề bài viết với animation
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: 1.0,
                          child: Text(
                            widget.article.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Nguồn tin
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.article.source.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Thông tin thời gian và lượt xem
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              widget.article.time,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.visibility, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            const Text('123K', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(width: 16),
                            const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            const Text('567', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Loading indicator mượt với animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: isLoadingContent && (fullContent == null || fullContent!.isEmpty) ? 60 : 0,
                          child: isLoadingContent && (fullContent == null || fullContent!.isEmpty)
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Đang tải nội dung đầy đủ...',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Nội dung bài viết với smooth transition
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey(displayContent),
                            child: Text(
                              displayContent,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.6,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Nút đọc bài gốc với animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(widget.article.link);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.article_outlined),
                            label: const Text(
                              'Đọc bài gốc',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
