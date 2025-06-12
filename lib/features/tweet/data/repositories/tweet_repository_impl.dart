// lib/features/tweet/data/repositories/tweet_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/tweet.dart';
import '../../domain/repositories/tweet_repository.dart';
import '../datasources/tweet_remote_data_source.dart';
import '../datasources/tweet_firestore_data_source.dart';
import '../../../../core/error/app_error.dart';

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
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'ツイートの取得に失敗しました: ${e.message}');
    } catch (e) {
      // Firestore取得に失敗したらAPIから取得（fallback）
      if (remoteDataSource != null) {
        try {
          return await remoteDataSource!.fetchTweets();
        } catch (e) {
          throw AppError.network(e, 'ツイートの取得に失敗しました。インターネット接続を確認してください。');
        }
      }
      throw AppError.unexpected(e, 'ツイートの取得に失敗しました。');
    }
  }

  @override
  Future<Tweet> createTweet(String content, auth.User user) async {
    try {
      if (content.trim().isEmpty) {
        throw AppError.validation('ツイート内容を入力してください');
      }
      return await firestoreDataSource.createTweet(content, user);
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'ツイートの作成に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'ツイートの作成に失敗しました。');
    }
  }

  @override
  Stream<List<Tweet>> tweetsStream() {
    try {
      return firestoreDataSource.tweetsStream().handleError((error) {
        if (error is FirebaseException) {
          throw AppError.database(error, 'ツイートの取得に失敗しました: ${error.message}');
        }
        throw AppError.unexpected(error, 'ツイートの取得に失敗しました。');
      });
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'ツイートの取得に失敗しました。');
    }
  }

  @override
  Future<List<Tweet>> fetchTweetsByAuthor(String authorId) async {
    try {
      if (authorId.trim().isEmpty) {
        throw AppError.validation('ユーザーIDが無効です');
      }
      return await firestoreDataSource.fetchTweetsByAuthor(authorId);
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'ユーザーのツイート取得に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'ユーザーのツイート取得に失敗しました。');
    }
  }

  @override
  Stream<List<Tweet>> tweetsByAuthorStream(String authorId) {
    try {
      if (authorId.trim().isEmpty) {
        throw AppError.validation('ユーザーIDが無効です');
      }
      return firestoreDataSource.tweetsByAuthorStream(authorId).handleError((
        error,
      ) {
        if (error is FirebaseException) {
          throw AppError.database(
            error,
            'ユーザーのツイート取得に失敗しました: ${error.message}',
          );
        }
        throw AppError.unexpected(error, 'ユーザーのツイート取得に失敗しました。');
      });
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'ユーザーのツイート取得に失敗しました。');
    }
  }

  @override
  Future<void> toggleLike(String tweetId, String userId) async {
    try {
      if (tweetId.trim().isEmpty) {
        throw AppError.validation('ツイートIDが無効です');
      }
      if (userId.trim().isEmpty) {
        throw AppError.validation('ユーザーIDが無効です');
      }

      await firestoreDataSource.toggleLike(tweetId, userId);
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'いいね操作に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'いいね操作に失敗しました。');
    }
  }

  @override
  Future<bool> isLikedByUser(String tweetId, String userId) async {
    try {
      if (tweetId.trim().isEmpty) {
        throw AppError.validation('ツイートIDが無効です');
      }
      if (userId.trim().isEmpty) {
        throw AppError.validation('ユーザーIDが無効です');
      }

      return await firestoreDataSource.isLikedByUser(tweetId, userId);
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'いいね状態の確認に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'いいね状態の確認に失敗しました。');
    }
  }
}
