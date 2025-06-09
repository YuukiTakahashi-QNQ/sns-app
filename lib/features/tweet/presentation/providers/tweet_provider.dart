// lib/features/tweet/presentation/providers/tweet_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/tweet_remote_data_source.dart';
import '../../data/datasources/tweet_firestore_data_source.dart';
import '../../data/repositories/tweet_repository_impl.dart';
import '../../domain/entities/tweet.dart';
import '../../domain/repositories/tweet_repository.dart';
import '../../domain/usecases/create_tweet_usecase.dart';
import '../../domain/usecases/fetch_tweets_usecase.dart';
import '../../domain/usecases/fetch_tweets_by_author_usecase.dart';
import '../../domain/usecases/get_tweets_stream_usecase.dart';
import '../../domain/usecases/get_tweets_by_author_stream_usecase.dart';
import 'tweet_state.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';

// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Datasource providers
final tweetRemoteDataSourceProvider = Provider<TweetRemoteDataSource>((ref) {
  return TweetRemoteDataSourceImpl();
});

final tweetFirestoreDataSourceProvider = Provider<TweetFirestoreDataSource>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return TweetFirestoreDataSourceImpl(firestore: firestore);
});

// Repository provider
final tweetRepositoryProvider = Provider<TweetRepository>((ref) {
  final remoteDataSource = ref.watch(tweetRemoteDataSourceProvider);
  final firestoreDataSource = ref.watch(tweetFirestoreDataSourceProvider);
  return TweetRepositoryImpl(
    remoteDataSource: remoteDataSource,
    firestoreDataSource: firestoreDataSource,
  );
});

// Use case providers
final fetchTweetsUseCaseProvider = Provider<FetchTweetsUseCase>((ref) {
  final repository = ref.watch(tweetRepositoryProvider);
  return FetchTweetsUseCase(repository);
});

final createTweetUseCaseProvider = Provider<CreateTweetUseCase>((ref) {
  final repository = ref.watch(tweetRepositoryProvider);
  return CreateTweetUseCase(repository);
});

final getTweetsStreamUseCaseProvider = Provider<GetTweetsStreamUseCase>((ref) {
  final repository = ref.watch(tweetRepositoryProvider);
  return GetTweetsStreamUseCase(repository);
});

// 特定ユーザーのツイート取得のためのユースケースプロバイダー
final fetchTweetsByAuthorUseCaseProvider = Provider<FetchTweetsByAuthorUseCase>(
  (ref) {
    final repository = ref.watch(tweetRepositoryProvider);
    return FetchTweetsByAuthorUseCase(repository);
  },
);

// 特定ユーザーのツイートストリーム取得のためのユースケースプロバイダー
final getTweetsByAuthorStreamUseCaseProvider =
    Provider<GetTweetsByAuthorStreamUseCase>((ref) {
      final repository = ref.watch(tweetRepositoryProvider);
      return GetTweetsByAuthorStreamUseCase(repository);
    });

// Tweet state provider
final tweetStateProvider =
    StateNotifierProvider<TweetStateNotifier, TweetState>((ref) {
      final fetchTweetsUseCase = ref.watch(fetchTweetsUseCaseProvider);
      final createTweetUseCase = ref.watch(createTweetUseCaseProvider);
      final getTweetsStreamUseCase = ref.watch(getTweetsStreamUseCaseProvider);

      return TweetStateNotifier(
        fetchTweetsUseCase: fetchTweetsUseCase,
        createTweetUseCase: createTweetUseCase,
        getTweetsStreamUseCase: getTweetsStreamUseCase,
      );
    });

// 拡張版ツイートStateNotifierProvider
final extendedTweetStateProvider =
    StateNotifierProvider<TweetStateNotifier, TweetState>((ref) {
      final fetchTweetsUseCase = ref.watch(fetchTweetsUseCaseProvider);
      final createTweetUseCase = ref.watch(createTweetUseCaseProvider);
      final getTweetsStreamUseCase = ref.watch(getTweetsStreamUseCaseProvider);
      final fetchTweetsByAuthorUseCase = ref.watch(
        fetchTweetsByAuthorUseCaseProvider,
      );
      final getTweetsByAuthorStreamUseCase = ref.watch(
        getTweetsByAuthorStreamUseCaseProvider,
      );

      return TweetStateNotifier(
        fetchTweetsUseCase: fetchTweetsUseCase,
        createTweetUseCase: createTweetUseCase,
        getTweetsStreamUseCase: getTweetsStreamUseCase,
        fetchTweetsByAuthorUseCase: fetchTweetsByAuthorUseCase,
        getTweetsByAuthorStreamUseCase: getTweetsByAuthorStreamUseCase,
      );
    });

// Future provider for tweets (simplified access)
final tweetsProvider = FutureProvider<List<Tweet>>((ref) async {
  final fetchTweetsUseCase = ref.watch(fetchTweetsUseCaseProvider);
  return await fetchTweetsUseCase();
});

// Stream provider for tweets (realtime updates)
final tweetsStreamProvider = StreamProvider<List<Tweet>>((ref) {
  final getTweetsStreamUseCase = ref.watch(getTweetsStreamUseCaseProvider);
  return getTweetsStreamUseCase();
});

// 特定ユーザーのツイート取得用のプロバイダー (authorId指定)
final tweetsByAuthorProvider = FutureProvider.family<List<Tweet>, String>((
  ref,
  authorId,
) async {
  final fetchTweetsByAuthorUseCase = ref.watch(
    fetchTweetsByAuthorUseCaseProvider,
  );
  return await fetchTweetsByAuthorUseCase(authorId);
});

// 特定ユーザーのツイートストリーム用のプロバイダー (authorId指定)
final tweetsByAuthorStreamProvider = StreamProvider.family<List<Tweet>, String>(
  (ref, authorId) {
    final getTweetsByAuthorStreamUseCase = ref.watch(
      getTweetsByAuthorStreamUseCaseProvider,
    );
    return getTweetsByAuthorStreamUseCase(authorId);
  },
);

// テスト用の固定ユーザーID (Firebaseコンソールからの指定ユーザー)
final testUserIdProvider = Provider<String>((ref) => 'test-user-uid-001');

// テストユーザーのツイート取得用プロバイダー
final testUserTweetsProvider = FutureProvider<List<Tweet>>((ref) async {
  final authorId = ref.watch(testUserIdProvider);
  final fetchTweetsByAuthorUseCase = ref.watch(
    fetchTweetsByAuthorUseCaseProvider,
  );
  return await fetchTweetsByAuthorUseCase(authorId);
});

// テストユーザーのツイートストリーム用プロバイダー
final testUserTweetsStreamProvider = StreamProvider<List<Tweet>>((ref) {
  final authorId = ref.watch(testUserIdProvider);
  final getTweetsByAuthorStreamUseCase = ref.watch(
    getTweetsByAuthorStreamUseCaseProvider,
  );
  return getTweetsByAuthorStreamUseCase(authorId);
});

// 現在のログイン中ユーザーIDを提供するProvider
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    return authState.user!.id;
  }
  return null;
});

// ログイン中のユーザー自身のツイートを取得するProvider
final currentUserTweetsProvider = FutureProvider<List<Tweet>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  // ユーザーがログインしていない場合は空のリストを返す
  if (userId == null) return [];

  final fetchTweetsByAuthorUseCase = ref.watch(
    fetchTweetsByAuthorUseCaseProvider,
  );
  return await fetchTweetsByAuthorUseCase(userId);
});

// ログイン中のユーザー自身のツイートをリアルタイムで取得するProvider
final currentUserTweetsStreamProvider = StreamProvider<List<Tweet>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  // ユーザーがログインしていない場合は空のストリームを返す
  if (userId == null) return Stream.value([]);

  final getTweetsByAuthorStreamUseCase = ref.watch(
    getTweetsByAuthorStreamUseCaseProvider,
  );
  return getTweetsByAuthorStreamUseCase(userId);
});

// ユーザー選択のためのStateProvider
final selectedUserTypeProvider = StateProvider<String>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  // ログインユーザーがいればそのユーザー、いなければテストユーザー
  return currentUserId != null ? 'current' : 'test';
});

// 選択されたユーザーのツイートストリームを提供するProvider
final selectedUserTweetsStreamProvider = Provider<StreamProvider<List<Tweet>>>((
  ref,
) {
  final selectedUserType = ref.watch(selectedUserTypeProvider);

  if (selectedUserType == 'current') {
    return currentUserTweetsStreamProvider;
  } else {
    return testUserTweetsStreamProvider;
  }
});
