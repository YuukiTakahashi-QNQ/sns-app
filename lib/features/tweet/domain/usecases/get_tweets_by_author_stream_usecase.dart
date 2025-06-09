// lib/features/tweet/domain/usecases/get_tweets_by_author_stream_usecase.dart
import '../entities/tweet.dart';
import '../repositories/tweet_repository.dart';

class GetTweetsByAuthorStreamUseCase {
  final TweetRepository repository;

  GetTweetsByAuthorStreamUseCase(this.repository);

  Stream<List<Tweet>> call(String authorId) {
    return repository.tweetsByAuthorStream(authorId);
  }
}
