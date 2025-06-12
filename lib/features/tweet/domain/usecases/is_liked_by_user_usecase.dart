// lib/features/tweet/domain/usecases/is_liked_by_user_usecase.dart
import '../repositories/tweet_repository.dart';

class IsLikedByUserUseCase {
  final TweetRepository repository;

  IsLikedByUserUseCase(this.repository);

  Future<bool> call(String tweetId, String userId) async {
    return await repository.isLikedByUser(tweetId, userId);
  }
}
