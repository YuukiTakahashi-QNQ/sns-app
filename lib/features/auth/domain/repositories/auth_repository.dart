import '../entities/user.dart';
abstract class AuthRepository {
  // サインアップ（新規登録）
  Future<User> signUp(String email, String password);

  // サインイン（ログイン）
  Future<User> signIn(String email, String password);

  // サインアウト（ログアウト）
  Future<void> signOut();

  // 現在のログインユーザー取得
  Future<User?> getCurrentUser();

  // ユーザープロフィール更新
  Future<User> updateUserProfile({String? displayName, String? photoUrl});
}