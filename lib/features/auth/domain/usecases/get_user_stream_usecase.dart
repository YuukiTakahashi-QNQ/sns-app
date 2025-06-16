// lib/features/auth/domain/usecases/get_user_stream_usecase.dart
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUserStreamUseCase {
  final UserRepository repository;

  GetUserStreamUseCase(this.repository);

  Stream<User> call(String userId) {
    return repository.userStream(userId);
  }
}
