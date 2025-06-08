// lib/features/auth/data/repositories/auth_repository_impl.dart
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> signUp(String email, String password) async {
    return await remoteDataSource.signUp(email, password);
  }

  @override
  Future<User> signIn(String email, String password) async {
    return await remoteDataSource.signIn(email, password);
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
  }

  @override
  Future<User?> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }

  @override
  Future<User> updateUserProfile({String? displayName, String? photoUrl}) async {
    return await remoteDataSource.updateUserProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}