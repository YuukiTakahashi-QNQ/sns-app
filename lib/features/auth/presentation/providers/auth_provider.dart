// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import 'auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

// リポジトリのプロバイダー
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = AuthRemoteDataSourceImpl(
    firebaseAuth: firebase.FirebaseAuth.instance
  );
  return AuthRepositoryImpl(remoteDataSource: dataSource);
});

// ユースケースのプロバイダー群
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInUseCase(repository);
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpUseCase(repository);
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

final updateUserProfileUseCaseProvider = Provider<UpdateUserProfileUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdateUserProfileUseCase(repository);
});

// 認証状態を管理するStateNotifierProvider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final signInUseCase = ref.watch(signInUseCaseProvider);
  final signUpUseCase = ref.watch(signUpUseCaseProvider);
  final signOutUseCase = ref.watch(signOutUseCaseProvider);
  final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
  final updateUserProfileUseCase = ref.watch(updateUserProfileUseCaseProvider);

  return AuthStateNotifier(
    signInUseCase: signInUseCase,
    signUpUseCase: signUpUseCase,
    signOutUseCase: signOutUseCase,
    getCurrentUserUseCase: getCurrentUserUseCase,
    updateUserProfileUseCase: updateUserProfileUseCase,
  );
});

// 認証状態の変更を管理するNotifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;

  AuthStateNotifier({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.updateUserProfileUseCase,
  }) : super(AuthState.initial()) {
    // 初期化時に現在のユーザー状態を確認
    checkCurrentUser();
  }

  // 現在のログイン状態をチェック
  Future<void> checkCurrentUser() async {
    state = AuthState.loading();
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // サインアップ処理
  Future<void> signUp(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await signUpUseCase(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // サインイン処理
  Future<void> signIn(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await signInUseCase(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // サインアウト処理
  Future<void> signOut() async {
    state = AuthState.loading();
    try {
      await signOutUseCase();
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // プロフィール更新処理
  Future<void> updateUserProfile({String? displayName, String? photoUrl}) async {
    state = AuthState.loading();
    try {
      final updatedUser = await updateUserProfileUseCase(
        displayName: displayName,
        photoUrl: photoUrl
      );
      state = AuthState.authenticated(updatedUser);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}