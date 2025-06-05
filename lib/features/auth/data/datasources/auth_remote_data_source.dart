// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp(String email, String password);
  Future<UserModel> signIn(String email, String password);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateUserProfile({String? displayName, String? photoUrl});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase.FirebaseAuth _firebaseAuth;

  AuthRemoteDataSourceImpl({firebase.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance;

  @override
  Future<UserModel> signUp(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('ユーザー登録に失敗しました');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('ログインに失敗しました');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return UserModel.fromFirebaseUser(user);
    }
    return null;
  }

  @override
  Future<UserModel> updateUserProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = _firebaseAuth.currentUser;

      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await user.updateDisplayName(displayName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // 更新後のユーザー情報を取得
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;

      if (updatedUser == null) {
        throw Exception('ユーザー情報の取得に失敗しました');
      }

      return UserModel.fromFirebaseUser(updatedUser);
    } catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  // Firebaseのエラーをアプリ固有のエラーに変換
  Exception _handleFirebaseAuthError(dynamic e) {
    if (e is firebase.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('ユーザーが見つかりません');
        case 'wrong-password':
          return Exception('パスワードが間違っています');
        case 'email-already-in-use':
          return Exception('このメールアドレスは既に使用されています');
        case 'weak-password':
          return Exception('パスワードが弱すぎます');
        case 'invalid-email':
          return Exception('無効なメールアドレスです');
        default:
          return Exception('認証エラー: ${e.message}');
      }
    }
    return Exception('予期せぬエラー: $e');
  }
}