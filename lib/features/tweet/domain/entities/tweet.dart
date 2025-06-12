// lib/features/tweet/domain/entities/tweet.dart
class Tweet {
  final int? id;
  final String content;
  final String userId; // authorIdに相当
  final DateTime createdAt;
  final String userName;
  final String? userPhotoUrl;
  final List<String> likedBy; // いいねしたユーザーIDのリスト
  final int likeCount; // いいねの数

  Tweet({
    this.id,
    required this.content,
    required this.userId,
    required this.createdAt,
    required this.userName,
    this.userPhotoUrl,
    List<String>? likedBy,
    int? likeCount,
  }) : this.likedBy = likedBy ?? [],
       this.likeCount = likeCount ?? 0;

  // 特定のユーザーがいいねしているかどうかを判定するメソッド
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}
