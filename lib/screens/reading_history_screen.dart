import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/firestore_service.dart';
import '../widgets/article_card_horizontal.dart';
import '../utils/app_localizations.dart';
import '../widgets/localization_provider.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  final _firestoreService = FirestoreService();
  List<ArticleModel> _readingHistory = [];
  bool _isLoading = true;

  // Track language to reload on change
  String? _previousLanguage;

  @override
  void initState() {
    super.initState();
    _loadReadingHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check for language change
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';

    if (_previousLanguage != null && _previousLanguage != currentLanguage) {
      // Language changed, just update UI
      _previousLanguage = currentLanguage;
      if (mounted) {
        setState(() {});
      }
    } else if (_previousLanguage == null) {
      _previousLanguage = currentLanguage;
    }
  }

  Future<void> _loadReadingHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _firestoreService.getReadingHistory(limit: 100);
      setState(() {
        _readingHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reading history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final localizationProvider = LocalizationProvider.of(context);
    final currentLanguage = localizationProvider?.currentLanguage ?? 'vi';
    final loc = AppLocalizations(currentLanguage);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2740)
            : Colors.white,
        title: Text(
          loc.translate('clear_history_dialog_title'),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          loc.translate('clear_history_dialog_content'),
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              loc.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final success = await _firestoreService.clearReadingHistory();

      if (success) {
        setState(() {
          _readingHistory = [];
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('history_cleared')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('cannot_clear_history')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
          loc.translate('reading_history_title'),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_readingHistory.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
              onSelected: (value) {
                if (value == 'clear') {
                  _clearHistory();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        loc.translate('clear_history'),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : _readingHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.translate('no_reading_history'),
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.translate('reading_history_subtitle'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReadingHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _readingHistory.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ArticleCardHorizontal(
                          article: _readingHistory[index],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

