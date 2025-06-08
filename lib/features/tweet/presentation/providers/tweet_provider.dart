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
import '../../domain/usecases/get_tweets_stream_usecase.dart';
import 'tweet_state.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../../auth/presentation/providers/auth_provider.dart';

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
