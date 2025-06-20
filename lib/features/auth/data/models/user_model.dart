// lib/features/auth/data/models/user_model.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    bool isEmailVerified = false,
    List<String>? followers,
    List<String>? following,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
         id: id,
         email: email,
         displayName: displayName,
         photoUrl: photoUrl,
         isEmailVerified: isEmailVerified,
         followers: followers,
         following: following,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  // FirebaseのUserオブジェクトからUserModelへの変換
  factory UserModel.fromFirebaseUser(firebase.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      followers: [],
      following: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Firestoreドキュメントからのマッピング
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['display_name'],
      photoUrl: data['photo_url'],
      isEmailVerified: data['is_email_verified'] ?? false,
      followers: _parseStringList(data['followers']),
      following: _parseStringList(data['following']),
      createdAt:
          data['created_at'] != null
              ? (data['created_at'] as Timestamp).toDate()
              : null,
      updatedAt:
          data['updated_at'] != null
              ? (data['updated_at'] as Timestamp).toDate()
              : null,
    );
  }

  // FirestoreへのマッピングデータOを生成
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'is_email_verified': isEmailVerified,
      'followers': followers,
      'following': following,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // 文字列リストをパースするヘルパーメソッド
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }
}
