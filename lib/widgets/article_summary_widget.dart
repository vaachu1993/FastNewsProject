import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/summary_service.dart';

class ArticleSummaryWidget extends StatefulWidget {
  final ArticleModel article;

  const ArticleSummaryWidget({super.key, required this.article});

  @override
  State<ArticleSummaryWidget> createState() => _ArticleSummaryWidgetState();
}

class _ArticleSummaryWidgetState extends State<ArticleSummaryWidget> {
  final SummaryService _summaryService = SummaryService();
  bool _loading = false;
  String? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _summary = widget.article.summary;
  }

  Future<void> _generateSummary() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Lấy nội dung từ description hoặc title
      final content = widget.article.description ?? widget.article.title;

      final result = await _summaryService.getSummaryForArticle(
        articleId: widget.article.id,
        title: widget.article.title,
        content: content,
      );

      if (mounted) {
        setState(() {
          _loading = false;
          if (result != null && result.isNotEmpty) {
            _summary = result;
            // Cập nhật summary vào article model
            widget.article.summary = result;
            widget.article.summaryUpdatedAt = DateTime.now();
          } else {
            _error = 'Không thể tạo tóm tắt. Vui lòng thử lại sau.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Đã xảy ra lỗi: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Hiển thị tóm tắt nếu đã có - Compact & Beautiful
    if (_summary != null && _summary!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.green.shade900.withValues(alpha: 0.2)
              : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header compact
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tóm tắt AI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                    ),
                  ),
                ),
                if (widget.article.summaryUpdatedAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.green.shade800.withValues(alpha: 0.3)
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatTime(widget.article.summaryUpdatedAt!),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Summary content
            Text(
              _summary!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      );
    }

    // Hiển thị lỗi nếu có - Compact
    if (_error != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _generateSummary,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    // Nút tạo tóm tắt - Modern & Compact
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _generateSummary,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _loading
                    ? [Colors.grey.shade400, Colors.grey.shade500]
                    : [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: (_loading ? Colors.grey : Colors.green).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Text(
                  _loading ? 'Đang tạo tóm tắt...' : 'Tạo tóm tắt AI',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }
}

