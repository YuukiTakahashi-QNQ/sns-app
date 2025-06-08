// lib/features/tweet/data/datasources/tweet_firestore_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tweet.dart';
import '../models/tweet_model.dart';
import '../../../auth/domain/entities/user.dart' as auth;

abstract class TweetFirestoreDataSource {
  Future<List<TweetModel>> fetchTweets();
  Future<TweetModel> createTweet(String content, auth.User user);
  Stream<List<TweetModel>> tweetsStream();
}

class TweetFirestoreDataSourceImpl implements TweetFirestoreDataSource {
  final FirebaseFirestore _firestore;

  TweetFirestoreDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // コレクション参照
  CollectionReference get _tweetsCollection => _firestore.collection('tweets');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // ユーザー情報をFirestoreに保存（ユーザー登録時などに呼び出す）
  Future<void> saveUserData(auth.User user) async {
    await _usersCollection.doc(user.id).set({
      'id': user.id,
      'name': user.displayName ?? 'ユーザー',
      'email': user.email,
      'photoUrl': user.photoUrl,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<TweetModel>> fetchTweets() async {
    try {
      final querySnapshot =
          await _tweetsCollection
              .orderBy('created_at', descending: true)
              .limit(50)
              .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Firestoreのタイムスタンプ型をDartのDateTimeに変換
        final createdAt =
            (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();

        return TweetModel(
          id: int.tryParse(doc.id) ?? 0,
          content: data['content'] ?? '',
          userId: (data['user_id'] ?? '').toString(),
          createdAt: createdAt,
          userName: data['user_name'] ?? '不明なユーザー',
        );
      }).toList();
    } catch (e) {
      throw Exception('ツイート取得に失敗しました: $e');
    }
  }

  @override
  Future<TweetModel> createTweet(String content, auth.User user) async {
    try {
      // ユーザー情報を保存/更新
      await saveUserData(user);

      // 新しいツイートのデータ作成
      final newTweet = {
        'content': content,
        'user_id': user.id,
        'user_name': user.displayName ?? 'ユーザー',
        'user_photo_url': user.photoUrl,
        'created_at': FieldValue.serverTimestamp(),
      };

      // ツイートの保存
      final docRef = await _tweetsCollection.add(newTweet);

      // 保存したツイートを取得して返す
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data() as Map<String, dynamic>;

      // サーバータイムスタンプをDateTimeに変換
      final createdAt =
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
      return TweetModel(
        id: int.tryParse(docSnapshot.id) ?? 0,
        content: data['content'] ?? '',
        userId: (data['user_id'] ?? '').toString(),
        createdAt: createdAt,
        userName: data['user_name'] ?? '不明なユーザー',
      );
    } catch (e) {
      throw Exception('ツイート作成に失敗しました: $e');
    }
  }

  @override
  Stream<List<TweetModel>> tweetsStream() {
    return _tweetsCollection
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt =
                (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            return TweetModel(
              id: int.tryParse(doc.id) ?? 0,
              content: data['content'] ?? '',
              userId: (data['user_id'] ?? '').toString(),
              createdAt: createdAt,
              userName: data['user_name'] ?? '不明なユーザー',
            );
          }).toList();
        });
  }
}
