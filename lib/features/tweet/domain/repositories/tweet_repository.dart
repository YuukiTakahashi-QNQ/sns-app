// lib/features/tweet/domain/repositories/tweet_repository.dart
import '../../../auth/domain/entities/user.dart' as auth;
import '../entities/tweet.dart';

abstract class TweetRepository {
  Future<List<Tweet>> fetchTweets();
  Future<Tweet> createTweet(String content, auth.User user);
  Stream<List<Tweet>> tweetsStream();
}
