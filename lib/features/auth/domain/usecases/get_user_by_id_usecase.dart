// lib/features/auth/domain/usecases/get_user_by_id_usecase.dart
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUserByIdUseCase {
  final UserRepository repository;

  GetUserByIdUseCase(this.repository);

  Future<User?> call(String userId) {
    return repository.getUserById(userId);
  }
}
