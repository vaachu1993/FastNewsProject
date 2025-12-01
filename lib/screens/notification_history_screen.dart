import 'package:flutter/material.dart';
import '../models/notification_history_model.dart';
import '../models/article_model.dart';
import '../services/notification_history_service.dart';
import '../screens/article_detail_screen.dart';
import '../utils/app_localizations.dart';
import '../widgets/localization_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final NotificationHistoryService _historyService = NotificationHistoryService();
  List<NotificationHistoryModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Setup timeago locale
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _historyService.getNotificationHistory();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    await _historyService.markAllAsRead();
    _loadNotifications();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả thông báo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearAllNotifications();
      _loadNotifications();
    }
  }

  Future<void> _deleteNotification(String id) async {
    await _historyService.deleteNotification(id);
    _loadNotifications();
  }

  Future<void> _onNotificationTap(NotificationHistoryModel notification) async {
    // Đánh dấu đã đọc
    await _historyService.markAsRead(notification.id);
    _loadNotifications();

    // Navigate to article detail if has link
    if (notification.articleLink != null && notification.articleLink!.isNotEmpty) {
      final article = ArticleModel(
        id: notification.articleId ?? notification.id,
        title: notification.title,
        link: notification.articleLink!,
        description: notification.body,
        imageUrl: notification.imageUrl ?? '',
        time: notification.timestamp.toString(),
        source: notification.source,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
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
          currentLanguage == 'vi' ? 'Lịch sử thông báo' : 'Notification History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAll();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all, size: 20),
                      const SizedBox(width: 8),
                      Text(currentLanguage == 'vi' ? 'Đánh dấu đã đọc tất cả' : 'Mark all as read'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        currentLanguage == 'vi' ? 'Xóa tất cả' : 'Clear all',
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
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _notifications.isEmpty
              ? _buildEmptyState(currentLanguage)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification, currentLanguage);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(String currentLanguage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            currentLanguage == 'vi' ? 'Chưa có thông báo nào' : 'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentLanguage == 'vi'
                ? 'Các thông báo sẽ hiển thị ở đây'
                : 'Notifications will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationHistoryModel notification, String currentLanguage) {
    final timeAgo = currentLanguage == 'vi'
        ? timeago.format(notification.timestamp, locale: 'vi')
        : timeago.format(notification.timestamp, locale: 'en');

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentLanguage == 'vi' ? 'Đã xóa thông báo' : 'Notification deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  notification.isRead
                      ? Icons.notifications_outlined
                      : Icons.notifications_active,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          notification.source,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

