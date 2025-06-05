// lib/features/auth/domain/usecases/sign_in_usecase.dart
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<User> call(String email, String password) async {
    return await repository.signIn(email, password);
  }
}