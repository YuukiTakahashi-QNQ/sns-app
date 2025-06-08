// lib/features/tweet/domain/usecases/create_tweet_usecase.dart
import '../../../auth/domain/entities/user.dart' as auth;
import '../entities/tweet.dart';
import '../repositories/tweet_repository.dart';

class CreateTweetUseCase {
  final TweetRepository repository;

  CreateTweetUseCase(this.repository);

  Future<Tweet> call(String content, auth.User user) async {
    return await repository.createTweet(content, user);
  }
}
