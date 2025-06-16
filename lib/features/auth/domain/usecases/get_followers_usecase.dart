// lib/features/auth/domain/usecases/get_followers_usecase.dart
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetFollowersUseCase {
  final UserRepository repository;

  GetFollowersUseCase(this.repository);

  Future<List<User>> call(String userId) {
    return repository.getFollowers(userId);
  }
}
