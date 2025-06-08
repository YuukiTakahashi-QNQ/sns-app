// lib/features/auth/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('ユーザー情報が読み込めません'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('ログアウトしてもよろしいですか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authStateProvider.notifier).signOut();
                      },
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(
                  user.displayName?.substring(0, 1).toUpperCase() ??
                      user.email.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 40),
                )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                user.displayName ?? 'ユーザー',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              if (user.isEmailVerified)
                const Chip(
                  label: Text('認証済み'),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white),
                )
              else
                const Chip(
                  label: Text('未認証'),
                  backgroundColor: Colors.amber,
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // プロフィール編集画面へ遷移
                },
                child: const Text('プロフィールを編集'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}