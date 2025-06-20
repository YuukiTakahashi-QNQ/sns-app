class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> followers; // フォロワーのユーザーID一覧
  final List<String> following; // フォロー中のユーザーID一覧

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
    List<String>? followers,
    List<String>? following,
  }) : this.followers = followers ?? [],
       this.following = following ?? [];

  /// 特定のユーザーをフォロー中かどうかを判定するメソッド
  bool isFollowing(String userId) {
    return following.contains(userId);
  }

  /// フォロワー数を取得
  int get followersCount => followers.length;

  /// フォロー中の数を取得
  int get followingCount => following.length;
}
