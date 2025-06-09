// lib/features/tweet/domain/usecases/fetch_tweets_by_author_usecase.dart
import '../entities/tweet.dart';
import '../repositories/tweet_repository.dart';

class FetchTweetsByAuthorUseCase {
  final TweetRepository repository;

  FetchTweetsByAuthorUseCase(this.repository);

  Future<List<Tweet>> call(String authorId) async {
    return await repository.fetchTweetsByAuthor(authorId);
  }
}
