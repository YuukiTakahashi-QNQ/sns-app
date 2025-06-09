// lib/core/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTweetDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // 1分未満
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    }
    // 1時間未満
    else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    }
    // 24時間未満
    else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    }
    // 7日未満
    else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    }
    // それ以上の場合
    else {
      final formatter = DateFormat('yyyy年MM月dd日');
      return formatter.format(date);
    }
  }

  static String formatDetailDate(DateTime date) {
    final formatter = DateFormat('yyyy年MM月dd日 HH:mm');
    return formatter.format(date);
  }
}
