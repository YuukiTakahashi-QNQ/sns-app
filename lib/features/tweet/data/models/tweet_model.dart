// lib/features/tweet/data/models/tweet_model.dart
import '../../domain/entities/tweet.dart';
import '../../../../core/error/app_error.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TweetModel extends Tweet {
  // FirestoreのドキュメントのオリジナルのドキュメントIDを保存
  final String? firestoreId;

  TweetModel({
    int? id,
    required String content,
    required String userId,
    required DateTime createdAt,
    required String userName,
    String? userPhotoUrl,
    List<String>? likedBy,
    int? likeCount,
    this.firestoreId,
  }) : super(
         id: id,
         content: content,
         userId: userId,
         createdAt: createdAt,
         userName: userName,
         userPhotoUrl: userPhotoUrl,
         likedBy: likedBy,
         likeCount: likeCount,
       );

  /// JSONからTweetModelを生成するファクトリメソッド
  factory TweetModel.fromJson(Map<String, dynamic> json) {
    try {
      // Firestoreドキュメント ID を適切に処理
      String? firestoreId;
      if (json['document_id'] != null && json['document_id'] is String) {
        firestoreId = json['document_id'];
      } else if (json['id'] != null && json['id'] is String) {
        firestoreId = json['id'];
      }

      return TweetModel(
        id: _parseId(json),
        content: _parseContent(json),
        userId: _parseUserId(json),
        createdAt: _parseCreatedAt(json),
        userName: _parseUserName(json),
        userPhotoUrl: _parseUserPhotoUrl(json),
        likedBy: _parseLikedBy(json),
        likeCount: _parseLikeCount(json),
        firestoreId: firestoreId,
      );
    } catch (e) {
      print('JSON parsing error for tweet: ${json.toString()}');
      print('Error details: ${e.toString()}');
      throw AppError.database(e, 'ツイートデータの解析に失敗しました: ${e.toString()}');
    }
  }

  /// TweetModelをJSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'user_id': userId,
      'created_at': FieldValue.serverTimestamp(),
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'liked_by': likedBy,
      'like_count': likeCount,
    };
  }

  /// IDをパース
  static int? _parseId(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) {
      final parsedId = int.tryParse(id);
      if (parsedId != null) return parsedId;
      // Firestoreのドキュメントの場合、IDは文字列のまま使用
      return null;
    }
    throw AppError.validation('無効なツイートID形式です');
  }

  /// Firestoreのドキュメントの実際のID (文字列) を取得するメソッド
  /// これは `id` フィールドが null の場合にも使えるようにするため
  String? get documentId {
    String? result;
    // まずfirestoreIdを返す（これが最も信頼性が高い）
    if (firestoreId != null &&
        firestoreId!.isNotEmpty &&
        firestoreId != "null") {
      result = firestoreId;
    } else {
      // 次にtoJson()のidを試す
      final rawId = toJson()['id'];
      if (rawId != null &&
          rawId.toString().isNotEmpty &&
          rawId.toString() != "null") {
        result = rawId.toString();
      } else {
        // 最後にidフィールドを試す
        result = id?.toString();
      }
    }

    print(
      'documentId getter: firestoreId=$firestoreId, id=${id}, result=$result',
    );
    return result;
  }

  /// コンテンツをパース
  static String _parseContent(Map<String, dynamic> json) {
    final content = json['content'];
    if (content == null) {
      throw AppError.validation('ツイート内容は必須です');
    }
    if (content is! String) {
      throw AppError.validation('無効なツイート内容の形式です');
    }
    return content;
  }

  /// ユーザーIDをパース
  static String _parseUserId(Map<String, dynamic> json) {
    final userId = json['user_id'];
    if (userId == null || userId is! String) {
      throw AppError.validation('無効なユーザーID形式です');
    }
    return userId;
  }

  /// 作成日時をパース
  static DateTime _parseCreatedAt(Map<String, dynamic> json) {
    final createdAt = json['created_at'];

    // createdAtがnullの場合は現在時刻を使用
    if (createdAt == null) {
      return DateTime.now();
    }

    // Firestoreのタイムスタンプの場合
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    // すでにDateTimeオブジェクトの場合
    if (createdAt is DateTime) {
      return createdAt;
    }

    // 文字列の場合はパースを試みる
    if (createdAt is String) {
      try {
        return DateTime.parse(createdAt);
      } catch (e) {
        print('Warning: Failed to parse date string: $createdAt');
        return DateTime.now();
      }
    }

    // その他の形式の場合は現在時刻を返す
    print('Warning: Unsupported date format: $createdAt');
    return DateTime.now();
  }

  /// ユーザー名をパース
  static String _parseUserName(Map<String, dynamic> json) {
    final userName = json['user_name'];
    if (userName == null) return '不明なユーザー';
    if (userName is! String) {
      throw AppError.validation('無効なユーザー名形式です');
    }
    return userName;
  }

  /// ユーザー写真URLをパース
  static String? _parseUserPhotoUrl(Map<String, dynamic> json) {
    final photoUrl = json['user_photo_url'];
    if (photoUrl == null) return null;
    if (photoUrl is! String) {
      throw AppError.validation('無効な写真URL形式です');
    }
    return photoUrl;
  }

  /// いいねしたユーザーIDのリストをパース
  static List<String> _parseLikedBy(Map<String, dynamic> json) {
    final likedBy = json['liked_by'];
    if (likedBy == null) return [];

    if (likedBy is List) {
      return likedBy.map((item) => item.toString()).toList();
    }

    return [];
  }

  /// いいね数をパース
  static int _parseLikeCount(Map<String, dynamic> json) {
    final likeCount = json['like_count'];
    if (likeCount == null) return 0;

    if (likeCount is int) {
      return likeCount;
    }

    if (likeCount is String) {
      return int.tryParse(likeCount) ?? 0;
    }

    return 0;
  }
}
