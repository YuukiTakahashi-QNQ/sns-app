// lib/features/auth/domain/usecases/unfollow_user_usecase.dart
import '../repositories/user_repository.dart';

class UnfollowUserUseCase {
  final UserRepository repository;

  UnfollowUserUseCase(this.repository);

  Future<void> call(String currentUserId, String targetUserId) {
    return repository.unfollowUser(currentUserId, targetUserId);
  }
}
