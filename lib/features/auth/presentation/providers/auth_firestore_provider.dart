// lib/features/auth/presentation/providers/auth_firestore_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/auth_firestore_service.dart';
import '../../../tweet/presentation/providers/tweet_provider.dart';

/// AuthFirestoreServiceのProviderを定義
final authFirestoreServiceProvider = Provider<AuthFirestoreService>((ref) {
  final firebaseAuth = firebase.FirebaseAuth.instance;
  final firestore = ref.watch(firestoreProvider);

  return AuthFirestoreService(firebaseAuth: firebaseAuth, firestore: firestore);
});

/// テスト用ユーザー存在確認Provider
final ensureTestUserProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(authFirestoreServiceProvider);
  await service.ensureTestUserExists();
});

/// 認証状態とFirestoreデータ同期Provider
final syncAuthWithFirestoreProvider = Provider<void>((ref) {
  final service = ref.watch(authFirestoreServiceProvider);
  service.setupAuthStateListener();
  return;
});
