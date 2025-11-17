import 'dart:async';
import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../utils/date_formatter.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> with TickerProviderStateMixin {
  String? fullContent;
  bool isLoadingContent = false;
  bool isBookmarked = false;
  bool isCheckingBookmark = true;
  final _firestoreService = FirestoreService();
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
    _checkBookmarkStatus();
    _addToReadingHistory(); // Lưu vào lịch sử đọc
  }

  // Kiểm tra trạng thái bookmark
  Future<void> _checkBookmarkStatus() async {
    final bookmarked = await _firestoreService.isBookmarked(widget.article.link);
    setState(() {
      isBookmarked = bookmarked;
      isCheckingBookmark = false;
    });
  }

  // Thêm vào lịch sử đọc
  Future<void> _addToReadingHistory() async {
    await _firestoreService.addToReadingHistory(widget.article);
  }

  // Toggle bookmark
  Future<void> _toggleBookmark() async {
    // Hiển thị loading state
    setState(() {
      isCheckingBookmark = true;
    });

    try {
      final success = await _firestoreService.toggleBookmark(widget.article);

      if (!mounted) return;

      setState(() {
        isCheckingBookmark = false;
      });

      if (success) {
        // Cập nhật trạng thái bookmark
        final newBookmarkStatus = await _firestoreService.isBookmarked(widget.article.link);

        setState(() {
          isBookmarked = newBookmarkStatus;
        });

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isBookmarked ? 'Đã lưu bài viết vào bookmark' : 'Đã xóa khỏi bookmark',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: isBookmarked ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // Hiển thị lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Không thể lưu bookmark. Vui lòng thử lại.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _toggleBookmark,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in _toggleBookmark: $e');

      if (!mounted) return;

      setState(() {
        isCheckingBookmark = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
          // Làm sạch text ngay từ đầu
          text = _cleanText(text);

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
          text = _cleanText(text);

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

    // Join các đoạn với 2 xuống dòng để phân cách rõ ràng
    String content = contentParts.take(8).join('\n\n');

    // Làm sạch lần cuối
    content = _cleanText(content);

    return content.isNotEmpty ? content : 'Không thể tải nội dung đầy đủ từ nguồn gốc. Vui lòng nhấn "Đọc bài gốc" để xem toàn bộ bài viết.';
  }

  /// Làm sạch và chuẩn hóa text
  String _cleanText(String text) {
    return text
        // Loại bỏ tất cả khoảng trắng thừa (space, tab, newline)
        .replaceAll(RegExp(r'[\s\u00A0]+'), ' ')
        // Loại bỏ xuống dòng liên tiếp
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
        // Chuẩn hóa dấu ba chấm
        .replaceAll(RegExp(r'\.{3,}'), '...')
        // Loại bỏ khoảng trắng ở đầu và cuối dòng
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        // Trim toàn bộ
        .trim();
  }

  /// Chia sẻ bài viết
  Future<void> _shareArticle() async {
    try {
      // Tạo nội dung chia sẻ
      final String shareText = '''
📰 ${widget.article.title}

📅 ${DateFormatter.formatDateTime(widget.article.time)}
📍 Nguồn: ${widget.article.source}

🔗 Đọc bài viết đầy đủ tại:
${widget.article.link}

---
Chia sẻ từ FastNews 📱
''';

      // Hiển thị dialog chia sẻ
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          text: shareText,
          subject: widget.article.title,
        ),
      );

      // Thành công - hiển thị snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Đang chia sẻ bài viết...',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
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
    } catch (e) {
      print('❌ Error sharing article: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không thể chia sẻ bài viết: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _shareArticle,
            ),
          ),
        );
      }
    }
  }

  /// Chia sẻ bài viết với tùy chọn nâng cao
  Future<void> _showShareOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Chia sẻ bài viết',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Options
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share, color: Colors.blue),
                ),
                title: const Text(
                  'Chia sẻ văn bản',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Chia sẻ tiêu đề và link bài viết',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareArticle();
                },
              ),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.link, color: Colors.green),
                ),
                title: const Text(
                  'Chỉ chia sẻ link',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Chia sẻ đường dẫn bài viết gốc',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareLink();
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Chia sẻ chỉ link
  Future<void> _shareLink() async {
    try {
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          text: widget.article.link,
          subject: widget.article.title,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Đang chia sẻ link bài viết...'),
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
    } catch (e) {
      print('❌ Error sharing link: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Không thể chia sẻ: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// Mở bài viết gốc trong trình duyệt
  Future<void> _openOriginalArticle() async {
    try {
      final uri = Uri.parse(widget.article.link);

      print('🌐 Attempting to open URL: ${uri.toString()}');

      // Thử mở URL với nhiều mode khác nhau
      bool launched = false;

      // Thử 1: External Application (mở browser riêng)
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ Launched with externalApplication: $launched');
      } catch (e) {
        print('❌ externalApplication failed: $e');
      }

      // Thử 2: Platform Default (nếu external fail)
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          print('✅ Launched with platformDefault: $launched');
        } catch (e) {
          print('❌ platformDefault failed: $e');
        }
      }

      // Thử 3: External Non-Browser Applications (fallback cuối)
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          print('✅ Launched with externalNonBrowserApplication: $launched');
        } catch (e) {
          print('❌ externalNonBrowserApplication failed: $e');
        }
      }

      // Nếu tất cả đều fail
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không thể mở bài viết. Vui lòng cài đặt trình duyệt (Chrome, Firefox...) trên thiết bị.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _openOriginalArticle,
            ),
          ),
        );
      } else if (launched && mounted) {
        // Thành công - hiển thị snackbar nhẹ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Đang mở bài viết trong trình duyệt...',
                  style: TextStyle(fontSize: 14),
                ),
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
    } catch (e) {
      print('❌ Error opening original article: $e');

      // Hiển thị lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lỗi: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _openOriginalArticle,
            ),
          ),
        );
      }
    }
  }

  String _stripHtmlTags(String htmlText) {
    String text = htmlText
        // Chuyển các thẻ HTML thành xuống dòng
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<li>', caseSensitive: false), '\n• ')
        // Loại bỏ tất cả thẻ HTML
        .replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '')
        // Decode HTML entities
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'");

    // Sử dụng _cleanText để chuẩn hóa
    return _cleanText(text);
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
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? const Color(0xFF5A7D3C) : Colors.black87,
            ),
            onPressed: isCheckingBookmark ? null : _toggleBookmark,
            tooltip: isBookmarked ? 'Bỏ lưu' : 'Lưu bài viết',
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
            onPressed: _showShareOptions,
            tooltip: 'Chia sẻ bài viết',
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

                        // Thông tin ngày đăng
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            const Text(
                              'Ngày đăng:',
                              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatDateTime(widget.article.time),
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
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
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.7,
                                letterSpacing: 0.3,
                                wordSpacing: 1.5,
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
                            onPressed: () => _openOriginalArticle(),
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

