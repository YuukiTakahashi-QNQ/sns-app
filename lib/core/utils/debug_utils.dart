// lib/core/utils/debug_utils.dart
import 'package:flutter/foundation.dart';
import '../../features/tweet/data/models/tweet_model.dart';

/// デバッグ情報を出力するユーティリティクラス
class DebugUtils {
  /// コンソールにTweetModelの詳細情報をダンプする
  static void dumpTweet(TweetModel tweet) {
    if (!kDebugMode) return; // リリースビルドでは無効

    try {
      print('---------- TWEET DEBUG INFO ----------');
      print('Tweet ID (int): ${tweet.id}');
      print('Firestore ID: ${tweet.firestoreId}');
      print('Document ID (getter): ${tweet.documentId}');
      print('Content: ${tweet.content}');
      print('User ID: ${tweet.userId}');
      print('Liked By: ${tweet.likedBy}');
      print('Like Count: ${tweet.likeCount}');
      print('Created At: ${tweet.createdAt}');
      print('------------------------------------');
    } catch (e) {
      print('Error dumping tweet info: $e');
    }
  }

  /// コンソールにメッセージを出力する (kDebugModeの場合のみ)
  static void log(String message, {String? tag}) {
    if (!kDebugMode) return;

    final logTag = tag != null ? '[$tag]' : '';
    print('$logTag $message');
  }
}
