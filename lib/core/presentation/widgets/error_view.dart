import 'package:flutter/material.dart';
import '../../error/app_error.dart';

/// エラー表示用のウィジェット
class ErrorView extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // エラータイプに応じたアイコンを選択
    IconData iconData;
    Color iconColor;
    switch (error.type) {
      case ErrorType.network:
        iconData = Icons.wifi_off;
        iconColor = Colors.orange;
        break;
      case ErrorType.auth:
        iconData = Icons.security;
        iconColor = Colors.red;
        break;
      case ErrorType.database:
        iconData = Icons.storage;
        iconColor = Colors.red;
        break;
      case ErrorType.validation:
        iconData = Icons.warning;
        iconColor = Colors.orange;
        break;
      case ErrorType.unexpected:
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (showRetryButton && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// エラーメッセージを表示するSnackBar
class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({super.key, required String message, VoidCallback? onRetry})
    : super(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('再試行', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      );
}
