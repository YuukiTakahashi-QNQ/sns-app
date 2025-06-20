// lib/features/auth/presentation/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/datasources/user_firestore_service.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_user_by_id_usecase.dart';
import '../../domain/usecases/follow_user_usecase.dart';
import '../../domain/usecases/unfollow_user_usecase.dart';
import '../../domain/usecases/get_followers_usecase.dart';
import '../../domain/usecases/get_following_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../domain/usecases/get_user_stream_usecase.dart';
import 'auth_provider.dart';

// UserFirestoreService プロバイダー
final userFirestoreServiceProvider = Provider<UserFirestoreService>((ref) {
  final firestore = FirebaseFirestore.instance;
  return UserFirestoreServiceImpl(firestore: firestore);
});

// UserRepository プロバイダー
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final userFirestoreService = ref.watch(userFirestoreServiceProvider);
  return UserRepositoryImpl(userFirestoreService: userFirestoreService);
});

// ユースケースのプロバイダー
final getUserByIdUseCaseProvider = Provider<GetUserByIdUseCase>((ref) {
  return GetUserByIdUseCase(ref.watch(userRepositoryProvider));
});

final followUserUseCaseProvider = Provider<FollowUserUseCase>((ref) {
  return FollowUserUseCase(ref.watch(userRepositoryProvider));
});

final unfollowUserUseCaseProvider = Provider<UnfollowUserUseCase>((ref) {
  return UnfollowUserUseCase(ref.watch(userRepositoryProvider));
});

final getFollowersUseCaseProvider = Provider<GetFollowersUseCase>((ref) {
  return GetFollowersUseCase(ref.watch(userRepositoryProvider));
});

final getFollowingUseCaseProvider = Provider<GetFollowingUseCase>((ref) {
  return GetFollowingUseCase(ref.watch(userRepositoryProvider));
});

final searchUsersUseCaseProvider = Provider<SearchUsersUseCase>((ref) {
  return SearchUsersUseCase(ref.watch(userRepositoryProvider));
});

final getUserStreamUseCaseProvider = Provider<GetUserStreamUseCase>((ref) {
  return GetUserStreamUseCase(ref.watch(userRepositoryProvider));
});

// 特定のユーザー情報を提供するプロバイダー（IDを指定）
final userByIdProvider = FutureProvider.family<User?, String>((
  ref,
  userId,
) async {
  final useCase = ref.watch(getUserByIdUseCaseProvider);
  return await useCase(userId);
});

// ユーザーのストリームを提供するプロバイダー
final userStreamProvider = StreamProvider.family<User, String>((ref, userId) {
  final useCase = ref.watch(getUserStreamUseCaseProvider);
  return useCase(userId);
});

// ユーザー検索結果を提供するプロバイダー
final userSearchProvider = FutureProvider.family<List<User>, String>((
  ref,
  query,
) async {
  final useCase = ref.watch(searchUsersUseCaseProvider);
  return await useCase(query);
});

// フォロワー一覧を提供するプロバイダー
final followersProvider = FutureProvider.family<List<User>, String>((
  ref,
  userId,
) async {
  final useCase = ref.watch(getFollowersUseCaseProvider);
  return await useCase(userId);
});

// フォロー中一覧を提供するプロバイダー
final followingProvider = FutureProvider.family<List<User>, String>((
  ref,
  userId,
) async {
  final useCase = ref.watch(getFollowingUseCaseProvider);
  return await useCase(userId);
});

// ユーザーのフォロー状態を管理するStateNotifierProvider
class FollowStateNotifier extends StateNotifier<AsyncValue<void>> {
  final FollowUserUseCase _followUserUseCase;
  final UnfollowUserUseCase _unfollowUserUseCase;

  FollowStateNotifier({
    required FollowUserUseCase followUserUseCase,
    required UnfollowUserUseCase unfollowUserUseCase,
  }) : _followUserUseCase = followUserUseCase,
       _unfollowUserUseCase = unfollowUserUseCase,
       super(const AsyncValue.data(null));

  Future<void> followUser(String currentUserId, String targetUserId) async {
    state = const AsyncValue.loading();
    try {
      await _followUserUseCase(currentUserId, targetUserId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    state = const AsyncValue.loading();
    try {
      await _unfollowUserUseCase(currentUserId, targetUserId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// フォロー操作のStateNotifierProviderを作成
final followStateProvider =
    StateNotifierProvider<FollowStateNotifier, AsyncValue<void>>((ref) {
      return FollowStateNotifier(
        followUserUseCase: ref.watch(followUserUseCaseProvider),
        unfollowUserUseCase: ref.watch(unfollowUserUseCaseProvider),
      );
    });
