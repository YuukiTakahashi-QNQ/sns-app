// lib/features/auth/presentation/providers/auth_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';

// 認証状態を表す列挙型
enum AuthStatus {
  initial, // 初期状態
  loading, // 読み込み中
  authenticated, // 認証済み
  unauthenticated, // 未認証
  needsDisplayName, // 表示名の設定が必要
  error, // エラー
}

// 認証状態を管理するクラス
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  // 新しいインスタンスを生成するコピーメソッド
  AuthState copyWith({AuthStatus? status, User? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  // 初期状態
  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  // ローディング状態
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  // 認証済み状態
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  // 未認証状態
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  // エラー状態
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}
