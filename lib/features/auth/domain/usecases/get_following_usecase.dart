// lib/features/auth/domain/usecases/get_following_usecase.dart
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetFollowingUseCase {
  final UserRepository repository;

  GetFollowingUseCase(this.repository);

  Future<List<User>> call(String userId) {
    return repository.getFollowing(userId);
  }
}
