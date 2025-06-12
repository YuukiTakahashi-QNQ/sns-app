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
  Future<void> toggleLike(String tweetId, String userId);
  Future<bool> isLikedByUser(String tweetId, String userId);
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
      } // 新しいツイートのデータ作成
      final newTweet = {
        'content': content.trim(),
        'user_id': user.id,
        'user_name': user.displayName?.trim() ?? 'ユーザー',
        'user_photo_url': user.photoUrl,
        'created_at': FieldValue.serverTimestamp(),
        'liked_by': [],
        'like_count': 0,
      };

      // トランザクションを使用してツイートを保存
      final docRef = _tweetsCollection.doc();
      await docRef.set(newTweet); // 保存したツイートを取得して返す
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw AppError.database(null, 'ツイートの保存に失敗しました');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      print('Created new tweet with document ID: ${docSnapshot.id}');
      return TweetModel.fromJson({
        ...data,
        'document_id': docSnapshot.id, // 専用のドキュメントIDフィールド
        'id': docSnapshot.id, // 後方互換性のために残す
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

  @override
  Future<void> toggleLike(String tweetId, String userId) async {
    try {
      if (tweetId.trim().isEmpty || userId.trim().isEmpty) {
        throw AppError.validation('無効なツイートIDまたはユーザーIDです');
      }

      // トランザクション前にドキュメントの存在確認
      print('【いいね処理】ツイートID: $tweetId, ユーザーID: $userId');

      // 事前確認
      final docExists = await _tweetsCollection
          .doc(tweetId)
          .get()
          .then((doc) => doc.exists)
          .catchError((e) {
            print('ドキュメントの存在確認中にエラー: $e');
            return false;
          });

      if (!docExists) {
        print('事前確認: ツイートドキュメントが見つかりません: $tweetId');
        throw AppError.database(null, 'ツイートが存在しません');
      }

      // トランザクションを使用して、いいねの追加/削除を実行
      return _firestore.runTransaction((transaction) async {
        final tweetRef = _tweetsCollection.doc(tweetId);
        final tweetDoc = await transaction.get(tweetRef);

        if (!tweetDoc.exists) {
          print('トランザクション内: ツイートドキュメントが見つかりません: $tweetId');
          throw AppError.database(null, 'ツイートが存在しません');
        }

        final data = tweetDoc.data() as Map<String, dynamic>;

        // Handle missing like fields
        List<String> likedBy = [];
        int likeCount = 0;

        // Extract liked_by with null checking
        if (data.containsKey('liked_by')) {
          likedBy = _parseStringList(data['liked_by']);
        }

        // Extract like_count with null checking
        if (data.containsKey('like_count') && data['like_count'] is int) {
          likeCount = data['like_count'];
        } else {
          // If like_count doesn't exist or is invalid, use the length of likedBy
          likeCount = likedBy.length;
        }

        // ユーザーがすでにいいねしている場合は削除、そうでなければ追加
        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          likeCount = likeCount > 0 ? likeCount - 1 : 0;
        } else {
          likedBy.add(userId);
          likeCount += 1;
        }

        // ドキュメントの更新
        transaction.update(tweetRef, {
          'liked_by': likedBy,
          'like_count': likeCount,
        });
      });
    } on FirebaseException catch (e) {
      print('Firebase error in toggleLike: ${e.code} - ${e.message}');
      print('Error details: ${e.toString()}');
      print('ツイートID: $tweetId, ユーザーID: $userId');

      if (e.code == 'permission-denied') {
        print('権限エラー: Firestoreのセキュリティルールで拒否されました');
        throw AppError.database(e, 'いいねの操作権限がありません');
      } else if (e.code == 'unavailable') {
        throw AppError.network(e, 'ネットワークエラーが発生しました');
      }
      throw AppError.database(e, 'いいね操作に失敗しました: ${e.message}');
    } catch (e, stackTrace) {
      if (e is AppError) rethrow;
      print('Unexpected error in toggleLike: $e\n$stackTrace');
      throw AppError.unexpected(e, 'いいね操作に失敗しました');
    }
  }

  @override
  Future<bool> isLikedByUser(String tweetId, String userId) async {
    try {
      if (tweetId.trim().isEmpty || userId.trim().isEmpty) {
        throw AppError.validation('無効なツイートIDまたはユーザーIDです');
      }

      final tweetDoc = await _tweetsCollection.doc(tweetId).get();
      if (!tweetDoc.exists) {
        throw AppError.database(null, 'ツイートが存在しません');
      }

      final data = tweetDoc.data() as Map<String, dynamic>;

      // Handle case where liked_by field might not exist
      if (!data.containsKey('liked_by')) {
        return false; // If liked_by doesn't exist, no one has liked the tweet
      }

      final likedBy = _parseStringList(data['liked_by']);
      return likedBy.contains(userId);
    } on FirebaseException catch (e) {
      print('Firebase error in isLikedByUser: ${e.code} - ${e.message}');
      throw AppError.database(e, 'いいね状態の確認に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'いいね状態の確認に失敗しました');
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

                // doc.idをdocument_idフィールドに設定して、確実にFirestoreドキュメントIDが保存されるようにする
                print('Converting document: ${doc.id}');

                // データを変換する前に、ドキュメントIDが含まれているか確認
                final modifiedData = {
                  ...data,
                  'document_id': doc.id, // 文字列としてドキュメントIDを専用フィールドに保存
                  'id':
                      data['id'] ?? doc.id, // 既存のidフィールドがあれば保持、なければドキュメントIDを使用
                  // serverTimestampがまだ処理されていない場合は現在時刻を使用
                  'created_at': data['created_at'] ?? DateTime.now(),
                };

                print(
                  'Modified data for document ${doc.id}: document_id=${modifiedData["document_id"]}, id=${modifiedData["id"]}',
                );

                return TweetModel.fromJson(modifiedData);
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

  // 文字列リストをパースするヘルパーメソッド
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    // Handle case where value is a single string (maybe a comma-separated list)
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return [];

      // Check if it might be a comma-separated list
      if (trimmed.contains(',')) {
        return trimmed
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      // Single value
      return [trimmed];
    }

    // Handle case where value is a Map (unlikely but being defensive)
    if (value is Map) {
      try {
        return value.keys.map((k) => k.toString()).toList();
      } catch (e) {
        print('Failed to convert Map to string list: $e');
        return [];
      }
    }

    // Fallback
    try {
      return [value.toString()];
    } catch (e) {
      print('Failed to convert value to string list: $e');
      return [];
    }
  }
}
