// lib/features/tweet/domain/usecases/fetch_tweets_usecase.dart
import '../entities/tweet.dart';
import '../repositories/tweet_repository.dart';

class FetchTweetsUseCase {
  final TweetRepository repository;

  FetchTweetsUseCase(this.repository);

  Future<List<Tweet>> call() async {
    return await repository.fetchTweets();
  }
}
