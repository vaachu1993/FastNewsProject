import 'package:flutter/material.dart';
import '../utils/network_utils.dart';

class NetworkStatusWidget extends StatefulWidget {
  final Widget child;
  final bool showOfflineBanner;
  final VoidCallback? onRetry;

  const NetworkStatusWidget({
    Key? key,
    required this.child,
    this.showOfflineBanner = true,
    this.onRetry,
  }) : super(key: key);

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget>
    with NetworkAwareMixin {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        if (widget.showOfflineBanner && !hasNetworkConnection)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.red.shade700,
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Không có kết nối mạng',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    refreshNetworkStatus();
                    widget.onRetry?.call();
                  },
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

class FirebaseErrorHandler extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const FirebaseErrorHandler({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = 'Lỗi kết nối';
    String message = 'Đã xảy ra lỗi kết nối';
    IconData icon = Icons.error_outline;
    Color color = Colors.red;

    // Parse error type
    if (error.contains('firestore.googleapis.com') ||
        error.contains('UNAVAILABLE') ||
        error.contains('Unable to resolve host')) {
      title = 'Lỗi mạng';
      message = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng và thử lại.';
      icon = Icons.wifi_off;
    } else if (error.contains('permission-denied')) {
      title = 'Lỗi quyền truy cập';
      message = 'Bạn không có quyền truy cập tính năng này.';
      icon = Icons.lock_outline;
    } else if (error.contains('unauthenticated')) {
      title = 'Chưa đăng nhập';
      message = 'Vui lòng đăng nhập để sử dụng tính năng này.';
      icon = Icons.person_outline;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 48),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingWithRetry extends StatelessWidget {
  final String message;
  final VoidCallback? onCancel;
  final bool showProgress;

  const LoadingWithRetry({
    Key? key,
    this.message = 'Đang tải...',
    this.onCancel,
    this.showProgress = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgress) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ],

          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          if (onCancel != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onCancel,
              child: const Text('Hủy'),
            ),
          ],
        ],
      ),
    );
  }
}
