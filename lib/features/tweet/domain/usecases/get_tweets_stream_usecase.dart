// lib/features/tweet/domain/usecases/get_tweets_stream_usecase.dart
import '../entities/tweet.dart';
import '../repositories/tweet_repository.dart';

class GetTweetsStreamUseCase {
  final TweetRepository repository;

  GetTweetsStreamUseCase(this.repository);

  Stream<List<Tweet>> call() {
    return repository.tweetsStream();
  }
}
