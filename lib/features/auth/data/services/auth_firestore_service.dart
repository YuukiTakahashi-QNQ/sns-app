// lib/features/auth/data/services/auth_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/entities/user.dart' as domain;
import '../../../../core/error/app_error.dart';

/// Firebase Auth とFirestore データを連携させるサービスクラス
class AuthFirestoreService {
  final firebase.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthFirestoreService({
    required firebase.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  /// ユーザードキュメントへの参照を取得
  DocumentReference _getUserDocRef(String userId) {
    if (userId.trim().isEmpty) {
      throw AppError.validation('ユーザーIDが無効です');
    }
    return _firestore.collection('users').doc(userId);
  }

  /// ユーザーのFirestoreデータを取得
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final docSnapshot = await _getUserDocRef(userId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      }
      return null;
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'ユーザーデータの取得に失敗しました: ${e.message}');
    } catch (e) {
      throw AppError.unexpected(e, 'ユーザーデータの取得に失敗しました');
    }
  }

  /// ユーザーをFirestoreに追加または更新
  Future<void> createOrUpdateUser(domain.User user) async {
    try {
      if (user.id.trim().isEmpty) {
        throw AppError.validation('ユーザーIDが無効です');
      }
      if (user.email.trim().isEmpty) {
        throw AppError.validation('メールアドレスが無効です');
      }
      await _getUserDocRef(user.id).set({
        'id': user.id,
        'email': user.email,
        'display_name': user.displayName ?? '',
        'photo_url': user.photoUrl,
        'is_email_verified': user.isEmailVerified,
        'followers': [], // 空のフォロワー配列を追加
        'following': [], // 空のフォロー中配列を追加
        'created_at': user.createdAt ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'ユーザー情報の保存に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'ユーザー情報の保存に失敗しました');
    }
  }

  /// Authイベントに応じてFirestoreデータをマッチングさせる
  Future<void> syncUserWithFirestore() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return;

      final userId = firebaseUser.uid;
      final userData = await getUserData(userId);

      // ユーザーデータが存在しない場合は新規作成
      if (userData == null) {
        final newUser = domain.User(
          id: userId,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
        );
        await createOrUpdateUser(newUser);
      } else {
        // ユーザーデータが存在する場合、フォローフィールドの存在を確認
        bool needsUpdate = false;
        final updateData = <String, dynamic>{
          'updated_at': FieldValue.serverTimestamp(),
        };

        // followersフィールドがない場合は追加
        if (!userData.containsKey('followers')) {
          updateData['followers'] = [];
          needsUpdate = true;
        }

        // followingフィールドがない場合は追加
        if (!userData.containsKey('following')) {
          updateData['following'] = [];
          needsUpdate = true;
        }

        // 更新が必要な場合のみFirestoreを更新
        if (needsUpdate) {
          await _getUserDocRef(userId).update(updateData);
          print('フォロー用フィールドをユーザー $userId に追加しました');
        }
      }
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'ユーザー情報の同期に失敗しました');
    }
  }

  /// テストユーザーデータが存在しない場合に作成
  Future<void> ensureTestUserExists() async {
    try {
      const testUserId = 'test-user-uid-001';
      final testUserData = await getUserData(testUserId);

      if (testUserData == null) {
        // トランザクションを使用してアトミックな操作を保証
        await _firestore.runTransaction((transaction) async {
          // テストユーザーが存在しない場合は作成
          final testUser = domain.User(
            id: testUserId,
            email: 'test@example.com',
            displayName: 'テストユーザー',
          );

          final userRef = _getUserDocRef(testUserId);
          final tweetRef = _firestore.collection('tweets').doc();
          transaction.set(userRef, {
            'id': testUser.id,
            'email': testUser.email,
            'display_name': testUser.displayName ?? '',
            'followers': [], // 空のフォロワー配列を追加
            'following': [], // 空のフォロー中配列を追加
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });

          transaction.set(tweetRef, {
            'content': 'Firebaseコンソールから最初の投稿です。',
            'user_id': testUserId,
            'created_at': FieldValue.serverTimestamp(),
            'user_name': 'テストユーザー',
          });
        });
      }
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'テストユーザーの作成に失敗しました: ${e.message}');
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError.unexpected(e, 'テストユーザーの作成に失敗しました');
    }
  }

  /// 認証イベントのリスナーを設定
  void setupAuthStateListener() {
    _firebaseAuth.authStateChanges().listen(
      (firebase.User? user) {
        if (user != null) {
          // ログイン時にFirestoreとの同期
          syncUserWithFirestore().catchError((error) {
            if (error is AppError) {
              throw error;
            }
            throw AppError.unexpected(error, 'Firestoreとの同期に失敗しました');
          });
        }
      },
      onError: (error) {
        if (error is AppError) {
          throw error;
        }
        throw AppError.unexpected(error, '認証状態の監視中にエラーが発生しました');
      },
    );
  }

  /// すべての既存ユーザーにフォローフィールドを追加する（管理者用）
  Future<void> addFollowFieldsToAllUsers() async {
    try {
      final usersCollection = _firestore.collection('users');
      final querySnapshot = await usersCollection.get();

      int updatedCount = 0;

      // 一度に多くのドキュメントを更新するとエラーになる可能性があるため、
      // バッチ処理を使用
      var batch = _firestore.batch();
      int batchCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final Map<String, dynamic> updates = {};
        bool needsUpdate = false;

        // followersフィールドがない場合は追加
        if (!data.containsKey('followers')) {
          updates['followers'] = [];
          needsUpdate = true;
        }

        // followingフィールドがない場合は追加
        if (!data.containsKey('following')) {
          updates['following'] = [];
          needsUpdate = true;
        }

        // 更新が必要な場合のみバッチに追加
        if (needsUpdate) {
          batch.update(doc.reference, updates);
          updatedCount++;
          batchCount++;

          // 450件ごとにバッチをコミットし、新しいバッチを作成
          // (Firestoreのバッチ上限は500件)
          if (batchCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      }

      // 残りのバッチをコミット
      if (batchCount > 0) {
        await batch.commit();
      }

      print('フォローフィールド追加完了: $updatedCount ユーザーを更新しました');
    } on FirebaseException catch (e) {
      throw AppError.database(e, 'ユーザー一括更新に失敗しました: ${e.message}');
    } catch (e) {
      throw AppError.unexpected(e, 'ユーザー一括更新に失敗しました');
    }
  }
}
