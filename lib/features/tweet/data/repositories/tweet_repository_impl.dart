// lib/features/tweet/data/repositories/tweet_repository_impl.dart
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/tweet.dart';
import '../../domain/repositories/tweet_repository.dart';
import '../datasources/tweet_remote_data_source.dart';
import '../datasources/tweet_firestore_data_source.dart';

class TweetRepositoryImpl implements TweetRepository {
  final TweetRemoteDataSource? remoteDataSource;
  final TweetFirestoreDataSource firestoreDataSource;

  TweetRepositoryImpl({
    this.remoteDataSource,
    required this.firestoreDataSource,
  });

  @override
  Future<List<Tweet>> fetchTweets() async {
    try {
      // Firebaseから取得を優先
      return await firestoreDataSource.fetchTweets();
    } catch (e) {
      // Firestore取得に失敗したらAPIから取得（fallback）
      if (remoteDataSource != null) {
        return await remoteDataSource!.fetchTweets();
      }
      rethrow;
    }
  }

  @override
  Future<Tweet> createTweet(String content, auth.User user) async {
    return await firestoreDataSource.createTweet(content, user);
  }

  @override
  Stream<List<Tweet>> tweetsStream() {
    return firestoreDataSource.tweetsStream();
  }
}
