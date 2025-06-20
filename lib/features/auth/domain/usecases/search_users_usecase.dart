// lib/features/auth/domain/usecases/search_users_usecase.dart
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class SearchUsersUseCase {
  final UserRepository repository;

  SearchUsersUseCase(this.repository);

  Future<List<User>> call(String query) {
    return repository.searchUsers(query);
  }
}
