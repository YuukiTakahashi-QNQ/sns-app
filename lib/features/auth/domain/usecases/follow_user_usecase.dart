// lib/features/auth/domain/usecases/follow_user_usecase.dart
import '../repositories/user_repository.dart';

class FollowUserUseCase {
  final UserRepository repository;

  FollowUserUseCase(this.repository);

  Future<void> call(String currentUserId, String targetUserId) {
    return repository.followUser(currentUserId, targetUserId);
  }
}
