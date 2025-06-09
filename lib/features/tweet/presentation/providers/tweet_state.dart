// lib/features/tweet/presentation/providers/tweet_state.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tweet.dart';
import '../../domain/usecases/create_tweet_usecase.dart';
import '../../domain/usecases/fetch_tweets_usecase.dart';
import '../../domain/usecases/get_tweets_stream_usecase.dart';
import '../../domain/usecases/fetch_tweets_by_author_usecase.dart';
import '../../domain/usecases/get_tweets_by_author_stream_usecase.dart';
import '../../../auth/domain/entities/user.dart' as auth;

enum TweetStatus { initial, loading, loaded, error }

class TweetState {
  final TweetStatus status;
  final List<Tweet> tweets;
  final String? errorMessage;

  TweetState({
    this.status = TweetStatus.initial,
    this.tweets = const [],
    this.errorMessage,
  });

  TweetState copyWith({
    TweetStatus? status,
    List<Tweet>? tweets,
    String? errorMessage,
  }) {
    return TweetState(
      status: status ?? this.status,
      tweets: tweets ?? this.tweets,
      errorMessage: errorMessage,
    );
  }

  factory TweetState.initial() => TweetState(status: TweetStatus.initial);
  factory TweetState.loading() => TweetState(status: TweetStatus.loading);
  factory TweetState.loaded(List<Tweet> tweets) =>
      TweetState(status: TweetStatus.loaded, tweets: tweets);
  factory TweetState.error(String message) =>
      TweetState(status: TweetStatus.error, errorMessage: message);
}

class TweetStateNotifier extends StateNotifier<TweetState> {
  final FetchTweetsUseCase fetchTweetsUseCase;
  final CreateTweetUseCase createTweetUseCase;
  final GetTweetsStreamUseCase getTweetsStreamUseCase;
  final FetchTweetsByAuthorUseCase? fetchTweetsByAuthorUseCase;
  final GetTweetsByAuthorStreamUseCase? getTweetsByAuthorStreamUseCase;
  StreamSubscription<List<Tweet>>? _tweetsSubscription;
  StreamSubscription<List<Tweet>>? _authorTweetsSubscription;
  String? _currentAuthorId;

  TweetStateNotifier({
    required this.fetchTweetsUseCase,
    required this.createTweetUseCase,
    required this.getTweetsStreamUseCase,
    this.fetchTweetsByAuthorUseCase,
    this.getTweetsByAuthorStreamUseCase,
  }) : super(TweetState.initial()) {
    // 初期化時にツイートを取得
    fetchTweets();
    // ストリームからリアルタイム更新を購読
    _subscribeTweetsUpdates();
  }

  void _subscribeTweetsUpdates() {
    _tweetsSubscription = getTweetsStreamUseCase().listen(
      (tweets) {
        state = TweetState.loaded(tweets);
      },
      onError: (error) {
        state = TweetState.error(error.toString());
      },
    );
  }

  Future<void> fetchTweets() async {
    state = TweetState.loading();
    try {
      final tweets = await fetchTweetsUseCase();
      state = TweetState.loaded(tweets);
    } catch (e) {
      state = TweetState.error(e.toString());
    }
  }

  Future<void> createTweet(String content, auth.User user) async {
    // 状態を変更しない - リアルタイム更新に任せる
    try {
      await createTweetUseCase(content, user);
      // 成功した場合は特に何もしない - Firestoreのリスナーが更新を検知する
    } catch (e) {
      state = TweetState.error(e.toString());
    }
  }

  // 特定ユーザーのツイートを取得
  Future<void> fetchTweetsByAuthor(String authorId) async {
    if (fetchTweetsByAuthorUseCase == null) {
      state = TweetState.error('特定ユーザーのツイート取得機能が利用できません');
      return;
    }

    state = TweetState.loading();
    try {
      final tweets = await fetchTweetsByAuthorUseCase!(authorId);
      state = TweetState.loaded(tweets);
      _currentAuthorId = authorId; // 現在表示中のユーザーIDを保存
    } catch (e) {
      state = TweetState.error(e.toString());
    }
  }

  // 特定ユーザーのツイートをリアルタイムで購読
  void subscribeToAuthorTweets(String authorId) {
    if (getTweetsByAuthorStreamUseCase == null) {
      state = TweetState.error('特定ユーザーのツイートストリーム機能が利用できません');
      return;
    }

    // 以前の購読をキャンセル
    _authorTweetsSubscription?.cancel();

    // 新しいストリームを購読
    _authorTweetsSubscription = getTweetsByAuthorStreamUseCase!(authorId)
        .listen(
          (tweets) {
            state = TweetState.loaded(tweets);
          },
          onError: (error) {
            state = TweetState.error(error.toString());
          },
        );

    _currentAuthorId = authorId;
  }

  // 特定のテストユーザーのツイートを取得する簡易メソッド
  Future<void> fetchTestUserTweets() async {
    await fetchTweetsByAuthor('test-user-uid-001');
  }

  // 特定のテストユーザーのツイートをリアルタイムで購読する簡易メソッド
  void subscribeToTestUserTweets() {
    subscribeToAuthorTweets('test-user-uid-001');
  }

  @override
  void dispose() {
    _tweetsSubscription?.cancel();
    _authorTweetsSubscription?.cancel();
    super.dispose();
  }
}
