// lib/features/tweet/data/models/tweet_model.dart
import '../../domain/entities/tweet.dart';

class TweetModel extends Tweet {
  TweetModel({
    int? id,
    required String content,
    required String userId,
    required DateTime createdAt,
    required String userName,
  }) : super(
         id: id,
         content: content,
         userId: userId,
         createdAt: createdAt,
         userName: userName,
       );
  factory TweetModel.fromJson(Map<String, dynamic> json) {
    return TweetModel(
      id: json['id'] as int,
      content: json['content'] as String,
      userId: json['user_id'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      userName: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'name': userName,
    };
  }
}
