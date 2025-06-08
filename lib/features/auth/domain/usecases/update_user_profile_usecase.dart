// lib/features/auth/domain/usecases/update_user_profile_usecase.dart
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateUserProfileUseCase {
  final AuthRepository repository;

  UpdateUserProfileUseCase(this.repository);

  Future<User> call({String? displayName, String? photoUrl}) async {
    return await repository.updateUserProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}