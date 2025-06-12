// lib/features/tweet/domain/usecases/toggle_like_usecase.dart
import '../repositories/tweet_repository.dart';

class ToggleLikeUseCase {
  final TweetRepository repository;

  ToggleLikeUseCase(this.repository);

  Future<void> call(String tweetId, String userId) async {
    return await repository.toggleLike(tweetId, userId);
  }
}
