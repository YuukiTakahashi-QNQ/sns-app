// lib/features/auth/data/repositories/user_repository_impl.dart
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_firestore_service.dart';

class UserRepositoryImpl implements UserRepository {
  final UserFirestoreService _userFirestoreService;

  UserRepositoryImpl({required UserFirestoreService userFirestoreService})
    : _userFirestoreService = userFirestoreService;

  @override
  Future<User?> getUserById(String userId) async {
    return await _userFirestoreService.getUserById(userId);
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    return await _userFirestoreService.searchUsers(query);
  }

  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {
    await _userFirestoreService.followUser(currentUserId, targetUserId);
  }

  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _userFirestoreService.unfollowUser(currentUserId, targetUserId);
  }

  @override
  Future<List<User>> getFollowers(String userId) async {
    return await _userFirestoreService.getFollowers(userId);
  }

  @override
  Future<List<User>> getFollowing(String userId) async {
    return await _userFirestoreService.getFollowing(userId);
  }

  @override
  Stream<User> userStream(String userId) {
    return _userFirestoreService.userStream(userId);
  }
}
