// lib/features/auth/domain/usecases/sign_up_usecase.dart
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<User> call(String email, String password) async {
    return await repository.signUp(email, password);
  }
}