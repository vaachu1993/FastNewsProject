import 'package:flutter/material.dart';
import 'dart:io';

class NetworkUtils {
  /// Check if device has internet connectivity
  static Future<bool> hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('❌ Network check failed: $e');
      return false;
    }
  }

  /// Show network error dialog with retry option
  static void showNetworkErrorDialog(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Lỗi mạng'),
            ],
          ),
          content: Text(
            customMessage ??
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry?.call();
              },
              child: const Text('Thử lại'),
            ),
          ],
        );
      },
    );
  }

  /// Show network status snackbar
  static void showNetworkStatusSnackBar(
    BuildContext context, {
    required bool isConnected,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected
                ? '✅ Đã kết nối mạng'
                : '❌ Mất kết nối mạng',
          ),
        ],
      ),
      backgroundColor: isConnected ? Colors.green : Colors.red,
      duration: Duration(seconds: isConnected ? 2 : 5),
      behavior: SnackBarBehavior.floating,
      action: !isConnected ? SnackBarAction(
        label: 'Thử lại',
        textColor: Colors.white,
        onPressed: () {
          // Trigger retry action
        },
      ) : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Execute operation with network retry
  static Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    String? operationName,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Check network before each attempt
        final hasNetwork = await hasNetworkConnection();
        if (!hasNetwork) {
          print('⚠️ No network connection (attempt $attempt/$maxRetries)');
          if (attempt == maxRetries) {
            throw const SocketException('No network connection after retries');
          }
          await Future.delayed(retryDelay);
          continue;
        }

        print('🔄 Executing ${operationName ?? 'operation'} (attempt $attempt/$maxRetries)');
        final result = await operation();
        print('✅ ${operationName ?? 'Operation'} successful on attempt $attempt');
        return result;

      } on SocketException catch (e) {
        print('🌐 Network error on attempt $attempt: $e');
        if (attempt == maxRetries) rethrow;
        await Future.delayed(retryDelay);
      } catch (e) {
        print('❌ Error on attempt $attempt: $e');
        if (attempt == maxRetries) rethrow;
        await Future.delayed(retryDelay);
      }
    }

    return null;
  }

  /// Get network error message based on exception
  static String getNetworkErrorMessage(dynamic error) {
    if (error is SocketException) {
      if (error.message.contains('firestore.googleapis.com')) {
        return '❌ Không thể kết nối đến cơ sở dữ liệu. Vui lòng kiểm tra kết nối mạng và thử lại.';
      }
      if (error.message.contains('No address associated with hostname')) {
        return '❌ Lỗi DNS: Không thể phân giải tên miền. Vui lòng kiểm tra cài đặt mạng.';
      }
      return '❌ Lỗi kết nối mạng: ${error.message}';
    }

    if (error.toString().contains('UNAVAILABLE')) {
      return '❌ Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';
    }

    if (error.toString().contains('DEADLINE_EXCEEDED')) {
      return '❌ Kết nối quá chậm. Vui lòng kiểm tra mạng và thử lại.';
    }

    return '❌ Đã xảy ra lỗi mạng. Vui lòng thử lại.';
  }

  /// Simple network status widget
  static Widget buildNetworkStatusWidget({
    required bool hasConnection,
    VoidCallback? onRetry,
  }) {
    if (hasConnection) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Không có kết nối mạng',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Thử lại',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mixin for widgets that need network monitoring
mixin NetworkAwareMixin<T extends StatefulWidget> on State<T> {
  bool _hasNetworkConnection = true;

  bool get hasNetworkConnection => _hasNetworkConnection;

  @override
  void initState() {
    super.initState();
    _checkNetworkConnection();
  }

  Future<void> _checkNetworkConnection() async {
    final hasConnection = await NetworkUtils.hasNetworkConnection();
    if (mounted) {
      setState(() {
        _hasNetworkConnection = hasConnection;
      });
    }
  }

  /// Call this method to refresh network status
  Future<void> refreshNetworkStatus() async {
    await _checkNetworkConnection();
  }

  /// Execute network operation with UI feedback
  Future<T?> executeNetworkOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool showSnackBar = true,
  }) async {
    try {
      if (!_hasNetworkConnection) {
        if (showSnackBar && mounted) {
          NetworkUtils.showNetworkStatusSnackBar(context, isConnected: false);
        }
        return null;
      }

      return await NetworkUtils.executeWithRetry(
        operation,
        operationName: operationName,
      );
    } catch (e) {
      if (showSnackBar && mounted) {
        final message = NetworkUtils.getNetworkErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                refreshNetworkStatus();
              },
            ),
          ),
        );
      }
      return null;
    }
  }
}
