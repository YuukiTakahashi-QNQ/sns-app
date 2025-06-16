// lib/features/auth/domain/repositories/user_repository.dart
import '../../data/models/user_model.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<User?> getUserById(String userId);
  Future<List<User>> searchUsers(String query);
  Future<void> followUser(String currentUserId, String targetUserId);
  Future<void> unfollowUser(String currentUserId, String targetUserId);
  Future<List<User>> getFollowers(String userId);
  Future<List<User>> getFollowing(String userId);
  Stream<User> userStream(String userId);
}
