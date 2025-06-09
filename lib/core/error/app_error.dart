/// アプリケーションのエラー種別を定義する列挙型
enum ErrorType {
  network, // ネットワークエラー
  auth, // 認証関連エラー
  database, // データベースエラー
  validation, // 入力値検証エラー
  unexpected, // 予期せぬエラー
}

/// アプリケーション共通のエラークラス
class AppError implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    required this.type,
    this.originalError,
    this.stackTrace,
  });

  /// ネットワークエラーを生成するファクトリメソッド
  factory AppError.network(dynamic error, [String? message]) {
    return AppError(
      message: message ?? 'ネットワークエラーが発生しました',
      type: ErrorType.network,
      originalError: error,
    );
  }

  /// 認証エラーを生成するファクトリメソッド
  factory AppError.auth(dynamic error, [String? message]) {
    return AppError(
      message: message ?? '認証エラーが発生しました',
      type: ErrorType.auth,
      originalError: error,
    );
  }

  /// データベースエラーを生成するファクトリメソッド
  factory AppError.database(dynamic error, [String? message]) {
    return AppError(
      message: message ?? 'データベースエラーが発生しました',
      type: ErrorType.database,
      originalError: error,
    );
  }

  /// 入力値検証エラーを生成するファクトリメソッド
  factory AppError.validation(String message, [dynamic error]) {
    return AppError(
      message: message,
      type: ErrorType.validation,
      originalError: error,
    );
  }

  /// 予期せぬエラーを生成するファクトリメソッド
  factory AppError.unexpected(
    dynamic error, [
    String? message,
    StackTrace? stack,
  ]) {
    return AppError(
      message: message ?? '予期せぬエラーが発生しました',
      type: ErrorType.unexpected,
      originalError: error,
      stackTrace: stack,
    );
  }

  /// Firebaseのエラーコードからユーザーフレンドリーなメッセージを生成
  static String getFirebaseAuthMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'invalid-email':
        return '無効なメールアドレスです';
      case 'operation-not-allowed':
        return 'この操作は許可されていません';
      case 'weak-password':
        return 'パスワードが弱すぎます';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'user-not-found':
        return 'アカウントが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'invalid-credential':
        return '認証情報が無効です';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました';
      default:
        return 'エラーが発生しました: $code';
    }
  }

  @override
  String toString() => 'AppError: $message (Type: $type)';
}
