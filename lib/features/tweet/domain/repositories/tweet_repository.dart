// lib/features/tweet/domain/repositories/tweet_repository.dart
import '../../../auth/domain/entities/user.dart' as auth;
import '../entities/tweet.dart';

abstract class TweetRepository {
  Future<List<Tweet>> fetchTweets();
  Future<Tweet> createTweet(String content, auth.User user);
  Stream<List<Tweet>> tweetsStream();

  // 特定ユーザーのツイートを取得するメソッド
  Future<List<Tweet>> fetchTweetsByAuthor(String authorId);
  // 特定ユーザーのツイートをストリームで購読するメソッド
  Stream<List<Tweet>> tweetsByAuthorStream(String authorId);

  // いいね機能のメソッド
  Future<void> toggleLike(String tweetId, String userId);
  Future<bool> isLikedByUser(String tweetId, String userId);
}
