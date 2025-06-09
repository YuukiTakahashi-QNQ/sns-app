// lib/features/auth/presentation/providers/auth_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import '../../data/services/auth_firestore_service.dart';
import 'auth_state.dart';
import 'auth_firestore_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

// firebase storageのインスタンスを提供するプロバイダー
final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// リポジトリのプロバイダー
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = AuthRemoteDataSourceImpl(
    firebaseAuth: firebase.FirebaseAuth.instance,
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

final updateUserProfileUseCaseProvider = Provider<UpdateUserProfileUseCase>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdateUserProfileUseCase(repository);
});

// 認証状態を管理するStateNotifierProvider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  final signInUseCase = ref.watch(signInUseCaseProvider);
  final signUpUseCase = ref.watch(signUpUseCaseProvider);
  final signOutUseCase = ref.watch(signOutUseCaseProvider);
  final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
  final updateUserProfileUseCase = ref.watch(updateUserProfileUseCaseProvider);
  final authFirestoreService = ref.watch(authFirestoreServiceProvider);
  final storage = ref.watch(storageProvider);

  return AuthStateNotifier(
    signInUseCase: signInUseCase,
    signUpUseCase: signUpUseCase,
    signOutUseCase: signOutUseCase,
    getCurrentUserUseCase: getCurrentUserUseCase,
    updateUserProfileUseCase: updateUserProfileUseCase,
    authFirestoreService: authFirestoreService,
    storage: storage,
  );
});

// 認証状態の変更を管理するNotifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;
  final AuthFirestoreService authFirestoreService;
  final FirebaseStorage storage;

  AuthStateNotifier({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.updateUserProfileUseCase,
    required this.authFirestoreService,
    required this.storage,
  }) : super(AuthState.initial()) {
    // 初期化時に現在のユーザー状態を確認
    checkCurrentUser();
    // テストユーザーの存在確認
    _ensureTestUser();
  }

  // テストユーザーの存在確認
  Future<void> _ensureTestUser() async {
    await authFirestoreService.ensureTestUserExists();
  }

  // 現在のログイン状態をチェック
  Future<void> checkCurrentUser() async {
    state = AuthState.loading();
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        state = AuthState.authenticated(user);
        // Firestoreとの同期
        await authFirestoreService.syncUserWithFirestore();
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
      // Firestoreにユーザー情報を保存
      await authFirestoreService.createOrUpdateUser(user);
      // 新規登録後は名前の設定が必要な状態にする
      state = state.copyWith(status: AuthStatus.needsDisplayName, user: user);
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
      // Firestoreとの同期
      await authFirestoreService.syncUserWithFirestore();
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

  // 画像をアップロードしてURLを取得
  Future<String?> _uploadProfileImage(File imageFile) async {
    if (state.user == null) return null;

    try {
      final storageRef = storage.ref().child(
        'profile_images/${state.user!.id}.jpg',
      );
      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('画像のアップロードに失敗しました: ${e.toString()}');
    }
  }

  // プロフィール更新処理
  Future<void> updateUserProfile({String? displayName, File? imageFile}) async {
    if (state.user == null) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      String? photoUrl;
      if (imageFile != null) {
        photoUrl = await _uploadProfileImage(imageFile);
      }

      final updatedUser = await updateUserProfileUseCase(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      state = AuthState.authenticated(updatedUser);
      // Firestoreのユーザー情報も更新
      await authFirestoreService.createOrUpdateUser(updatedUser);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // 名前設定処理
  Future<void> setInitialDisplayName(String displayName) async {
    if (state.user == null) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final updatedUser = await updateUserProfileUseCase(
        displayName: displayName,
      );
      state = AuthState.authenticated(updatedUser);
      // Firestoreのユーザー情報も更新
      await authFirestoreService.createOrUpdateUser(updatedUser);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}
