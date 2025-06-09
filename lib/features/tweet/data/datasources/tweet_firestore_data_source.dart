// lib/features/tweet/data/datasources/tweet_firestore_data_source.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tweet.dart';
import '../models/tweet_model.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../../../core/error/app_error.dart';

abstract class TweetFirestoreDataSource {
  Future<List<TweetModel>> fetchTweets();
  Future<TweetModel> createTweet(String content, auth.User user);
  Stream<List<TweetModel>> tweetsStream();
  Future<List<TweetModel>> fetchTweetsByAuthor(String authorId);
  Stream<List<TweetModel>> tweetsByAuthorStream(String authorId);
}

class TweetFirestoreDataSourceImpl implements TweetFirestoreDataSource {
  final FirebaseFirestore _firestore;
  static const int _pageSize = 50;

  TweetFirestoreDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // コレクション参照
  CollectionReference get _tweetsCollection => _firestore.collection('tweets');

  @override
  Future<List<TweetModel>> fetchTweets() async {
    try {
      final querySnapshot = await _tweetsCollection
          .orderBy('created_at', descending: true)
          .limit(_pageSize)
          .get()
          .timeout(const Duration(seconds: 10));

      return _convertQuerySnapshotToTweets(querySnapshot);
    } on FirebaseException catch (e) {
      print('Firebase error in fetchTweets: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw AppError.database(e, 'ツイートの取得権限がありません');
      } else if (e.code == 'unavailable') {
        throw AppError.network(e, 'ネットワークエラーが発生しました');
      }
      throw AppError.database(e, 'ツイートの取得に失敗しました: ${e.message}');
    } on TimeoutException {
      throw AppError.network(null, 'タイムアウトが発生しました');
    } catch (e, stackTrace) {
      print('Unexpected error in fetchTweets: $e\n$stackTrace');
      throw AppError.unexpected(e, 'ツイートの取得に失敗しました');
    }
  }

  @override
  Future<TweetModel> createTweet(String content, auth.User user) async {
    try {
      // 入力値の検証
      if (content.trim().isEmpty) {
        throw AppError.validation('ツイート内容を入力してください');
      }
      if (user.id.trim().isEmpty) {
        throw AppError.validation('無効なユーザーIDです');
      }

      // 新しいツイートのデータ作成
      final newTweet = {
        'content': content.trim(),
        'user_id': user.id,
        'user_name': user.displayName?.trim() ?? 'ユーザー',
        'user_photo_url': user.photoUrl,
        'created_at': FieldValue.serverTimestamp(),
      };

      // トランザクションを使用してツイートを保存
      final docRef = _tweetsCollection.doc();
      await docRef.set(newTweet);

      // 保存したツイートを取得して返す
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw AppError.database(null, 'ツイートの保存に失敗しました');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      return TweetModel.fromJson({
        ...data,
        'id': docSnapshot.id,
        // serverTimestampがまだ処理されていない場合は現在時刻を使用
        'created_at': data['created_at'] ?? FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print('Firebase error in createTweet: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw AppError.database(e, 'ツイートの作成権限がありません');
      } else if (e.code == 'unavailable') {
        throw AppError.network(e, 'ネットワークエラーが発生しました');
      }
      throw AppError.database(e, 'ツイートの作成に失敗しました: ${e.message}');
    } catch (e, stackTrace) {
      if (e is AppError) rethrow;
      print('Unexpected error in createTweet: $e\n$stackTrace');
      throw AppError.unexpected(e, 'ツイートの作成に失敗しました');
    }
  }

  @override
  Stream<List<TweetModel>> tweetsStream() {
    try {
      return _tweetsCollection
          .orderBy('created_at', descending: true)
          .limit(_pageSize)
          .snapshots()
          .map(_convertQuerySnapshotToTweets)
          .handleError((error) {
            print('Error in tweetsStream: $error');
            if (error is FirebaseException) {
              throw AppError.database(
                error,
                'ツイートの取得に失敗しました: ${error.message}',
              );
            }
            throw AppError.unexpected(error, 'ツイートの取得に失敗しました');
          });
    } catch (e, stackTrace) {
      print('Unexpected error in tweetsStream: $e\n$stackTrace');
      throw AppError.unexpected(e, 'ツイートの取得に失敗しました');
    }
  }

  @override
  Future<List<TweetModel>> fetchTweetsByAuthor(String authorId) async {
    try {
      if (authorId.trim().isEmpty) {
        throw AppError.validation('ユーザーIDが無効です');
      }

      final querySnapshot = await _tweetsCollection
          .where('user_id', isEqualTo: authorId)
          .orderBy('created_at', descending: true)
          .limit(_pageSize)
          .get()
          .timeout(const Duration(seconds: 10));

      final tweets = _convertQuerySnapshotToTweets(querySnapshot);
      if (tweets.isEmpty) {
        print('No tweets found for author: $authorId');
        return []; // 空のリストを返す（エラーではない）
      }
      return tweets;
    } on FirebaseException catch (e) {
      print('Firebase error in fetchTweetsByAuthor: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw AppError.database(e, 'ツイートの取得権限がありません');
      } else if (e.code == 'unavailable') {
        throw AppError.network(e, 'ネットワークエラーが発生しました');
      }
      throw AppError.database(e, 'ユーザーのツイート取得に失敗しました: ${e.message}');
    } on TimeoutException {
      throw AppError.network(null, 'タイムアウトが発生しました');
    } catch (e, stackTrace) {
      if (e is AppError) rethrow;
      print('Unexpected error in fetchTweetsByAuthor: $e\n$stackTrace');
      throw AppError.unexpected(e, 'ユーザーのツイート取得に失敗しました');
    }
  }

  @override
  Stream<List<TweetModel>> tweetsByAuthorStream(String authorId) {
    try {
      if (authorId.trim().isEmpty) {
        throw AppError.validation('ユーザーIDが無効です');
      }

      print('Starting tweetsByAuthorStream for author: $authorId');
      return _tweetsCollection
          .where('user_id', isEqualTo: authorId)
          .orderBy('created_at', descending: true)
          .limit(_pageSize)
          .snapshots()
          .map(_convertQuerySnapshotToTweets)
          .handleError((error) {
            print('Error in tweetsByAuthorStream: $error');
            if (error is FirebaseException) {
              throw AppError.database(
                error,
                'ツイートの取得に失敗しました: ${error.message}',
              );
            }
            throw AppError.unexpected(error, 'ツイートの取得に失敗しました');
          });
    } catch (e, stackTrace) {
      print('Unexpected error in tweetsByAuthorStream: $e\n$stackTrace');
      throw AppError.unexpected(e, 'ユーザーのツイート取得に失敗しました');
    }
  }

  // QuerySnapshotからTweetModelのリストに変換するヘルパーメソッド
  List<TweetModel> _convertQuerySnapshotToTweets(QuerySnapshot querySnapshot) {
    final tweets =
        querySnapshot.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                // データの検証
                if (!_isValidTweetData(data)) {
                  print('Warning: Invalid tweet data for document ${doc.id}');
                  print('Data: $data');
                  return null;
                }
                return TweetModel.fromJson({
                  ...data,
                  'id': doc.id,
                  // serverTimestampがまだ処理されていない場合は現在時刻を使用
                  'created_at':
                      data['created_at'] ?? FieldValue.serverTimestamp(),
                });
              } catch (e, stackTrace) {
                print(
                  'Warning: Failed to parse tweet document ${doc.id}: $e\n$stackTrace',
                );
                print('Document data: ${doc.data()}');
                return null;
              }
            })
            .where((tweet) => tweet != null)
            .cast<TweetModel>()
            .toList();

    print(
      'Converted ${tweets.length} tweets from ${querySnapshot.docs.length} documents',
    );
    return tweets;
  }

  // ツイートデータの検証
  bool _isValidTweetData(Map<String, dynamic> data) {
    final requiredFields = ['content', 'user_id', 'user_name'];
    final hasAllFields = requiredFields.every(
      (field) => data.containsKey(field),
    );

    if (!hasAllFields) {
      print('Missing required fields. Data: $data');
      print('Required fields: $requiredFields');
      return false;
    }

    // 必須フィールドの値が適切な型かチェック
    final isContentValid =
        data['content'] is String &&
        data['content'].toString().trim().isNotEmpty;
    final isUserIdValid =
        data['user_id'] is String &&
        data['user_id'].toString().trim().isNotEmpty;
    final isUserNameValid = data['user_name'] is String;

    if (!isContentValid || !isUserIdValid || !isUserNameValid) {
      print(
        'Invalid field types or empty values. Content: ${data['content']}, UserId: ${data['user_id']}, UserName: ${data['user_name']}',
      );
      return false;
    }

    return true;
  }
}
