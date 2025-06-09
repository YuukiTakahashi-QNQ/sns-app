// lib/features/tweet/domain/entities/tweet.dart
class Tweet {
  final int? id;
  final String content;
  final String userId; // authorIdに相当
  final DateTime createdAt;
  final String userName;
  final String? userPhotoUrl;

  Tweet({
    this.id,
    required this.content,
    required this.userId,
    required this.createdAt,
    required this.userName,
    this.userPhotoUrl,
  });
}
