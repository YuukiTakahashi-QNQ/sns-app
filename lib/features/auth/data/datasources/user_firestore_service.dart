// lib/features/auth/data/datasources/user_firestore_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../../core/error/app_error.dart';

abstract class UserFirestoreService {
  Future<UserModel?> getUserById(String userId);
  Future<List<UserModel>> searchUsers(String query);
  Future<void> createOrUpdateUser(UserModel user);
  Future<void> followUser(String currentUserId, String targetUserId);
  Future<void> unfollowUser(String currentUserId, String targetUserId);
  Future<List<UserModel>> getFollowers(String userId);
  Future<List<UserModel>> getFollowing(String userId);
  Stream<UserModel> userStream(String userId);
}

class UserFirestoreServiceImpl implements UserFirestoreService {
  final FirebaseFirestore _firestore;

  UserFirestoreServiceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ユーザーコレクションの参照
  CollectionReference get _usersCollection => _firestore.collection('users');

  // ユーザーをIDで取得
  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      return UserModel.fromFirestore(data, docSnapshot.id);
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'ユーザー情報の取得に失敗しました: ${e.message}');
    } catch (e) {
      throw AppError.unexpected(e, 'ユーザー情報の取得に失敗しました');
    }
  }

  // ユーザーを検索
  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      // 名前による検索（前方一致）
      final querySnapshot =
          await _usersCollection
              .where('display_name', isGreaterThanOrEqualTo: query)
              .where('display_name', isLessThan: query + 'z')
              .limit(20)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromFirestore(data, doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'ユーザー検索に失敗しました: ${e.message}');
    } catch (e) {
      throw AppError.unexpected(e, 'ユーザー検索に失敗しました');
    }
  }

  // ユーザーを作成または更新
  @override
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _usersCollection
          .doc(user.id)
          .set(user.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'ユーザー情報の更新に失敗しました: ${e.message}');
    } catch (e) {
      throw AppError.unexpected(e, 'ユーザー情報の更新に失敗しました');
    }
  }

  // ユーザーをフォローする
  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) {
      throw AppError.validation('自分自身をフォローすることはできません');
    }

    try {
      // トランザクションを使用して整合性を保つ
      await _firestore.runTransaction((transaction) async {
        // 現在のユーザードキュメント
        final currentUserDoc = await transaction.get(
          _usersCollection.doc(currentUserId),
        );
        // フォロー対象のユーザードキュメント
        final targetUserDoc = await transaction.get(
          _usersCollection.doc(targetUserId),
        );

        if (!currentUserDoc.exists) {
          throw AppError.database(null, '現在のユーザーが存在しません');
        }

        if (!targetUserDoc.exists) {
          throw AppError.database(null, 'フォローしようとしているユーザーが存在しません');
        }

        final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
        final targetUserData = targetUserDoc.data() as Map<String, dynamic>;

        // 現在のユーザーのfollowingリスト
        List<String> following =
            currentUserData['following'] != null
                ? List<String>.from(currentUserData['following'])
                : [];

        // フォロー対象のユーザーのfollowersリスト
        List<String> followers =
            targetUserData['followers'] != null
                ? List<String>.from(targetUserData['followers'])
                : [];

        // すでにフォローしている場合は何もしない
        if (following.contains(targetUserId)) {
          return;
        }

        // フォロー関係を更新
        following.add(targetUserId);
        followers.add(currentUserId);

        // トランザクションで更新
        transaction.update(_usersCollection.doc(currentUserId), {
          'following': following,
        });

        transaction.update(_usersCollection.doc(targetUserId), {
          'followers': followers,
        });
      });
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'フォローに失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'フォローに失敗しました');
    }
  }

  // ユーザーのフォローを解除する
  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      // トランザクションを使用して整合性を保つ
      await _firestore.runTransaction((transaction) async {
        // 現在のユーザードキュメント
        final currentUserDoc = await transaction.get(
          _usersCollection.doc(currentUserId),
        );
        // フォロー対象のユーザードキュメント
        final targetUserDoc = await transaction.get(
          _usersCollection.doc(targetUserId),
        );

        if (!currentUserDoc.exists || !targetUserDoc.exists) {
          // どちらかのユーザーが存在しない場合は処理を終了
          return;
        }

        final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
        final targetUserData = targetUserDoc.data() as Map<String, dynamic>;

        // 現在のユーザーのfollowingリスト
        List<String> following =
            currentUserData['following'] != null
                ? List<String>.from(currentUserData['following'])
                : [];

        // フォロー対象のユーザーのfollowersリスト
        List<String> followers =
            targetUserData['followers'] != null
                ? List<String>.from(targetUserData['followers'])
                : [];

        // フォローしていない場合は何もしない
        if (!following.contains(targetUserId)) {
          return;
        }

        // フォロー関係を更新
        following.remove(targetUserId);
        followers.remove(currentUserId);

        // トランザクションで更新
        transaction.update(_usersCollection.doc(currentUserId), {
          'following': following,
        });

        transaction.update(_usersCollection.doc(targetUserId), {
          'followers': followers,
        });
      });
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'フォロー解除に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'フォロー解除に失敗しました');
    }
  }

  // ユーザーのフォロワー一覧を取得
  @override
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw AppError.database(null, 'ユーザーが存在しません');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final followers =
          userData['followers'] != null
              ? List<String>.from(userData['followers'])
              : <String>[];

      if (followers.isEmpty) {
        return [];
      }

      // フォロワーのユーザー情報を取得
      final querySnapshot =
          await _usersCollection
              .where(FieldPath.documentId, whereIn: followers)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromFirestore(data, doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'フォロワー一覧の取得に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'フォロワー一覧の取得に失敗しました');
    }
  }

  // ユーザーのフォロー中一覧を取得
  @override
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw AppError.database(null, 'ユーザーが存在しません');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final following =
          userData['following'] != null
              ? List<String>.from(userData['following'])
              : <String>[];

      if (following.isEmpty) {
        return [];
      }

      // フォロー中のユーザー情報を取得
      final querySnapshot =
          await _usersCollection
              .where(FieldPath.documentId, whereIn: following)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromFirestore(data, doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'フォロー中一覧の取得に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'フォロー中一覧の取得に失敗しました');
    }
  }

  // ユーザー情報のリアルタイム更新を監視するStream
  @override
  Stream<UserModel> userStream(String userId) {
    try {
      return _usersCollection
          .doc(userId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) {
              // ユーザーが存在しない場合は、代わりにエラーメッセージを含むデフォルトのUserModelを返す
              return UserModel(
                id: userId,
                email: 'unknown@example.com',
                displayName: 'Unknown User',
                isEmailVerified: false,
                followers: [],
                following: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }
            final data = doc.data() as Map<String, dynamic>;
            return UserModel.fromFirestore(data, doc.id);
          })
          .handleError((error) {
            print('ユーザーストリーム取得エラー: $error');
            // エラーが発生した場合でもストリームを終了させずに代替データを提供
            return UserModel(
              id: userId,
              email: 'error@example.com',
              displayName: 'Error Loading User',
              isEmailVerified: false,
              followers: [],
              following: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          });
    } catch (e) {
      // 全体的なエラーに対するハンドリング
      print('ユーザーストリーム作成エラー: $e');
      return Stream.value(
        UserModel(
          id: userId,
          email: 'error@example.com',
          displayName: 'Error Loading User',
          isEmailVerified: false,
          followers: [],
          following: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
}
