// lib/features/auth/presentation/pages/sign_in_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_form.dart';

class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // 認証状態を監視し、認証済みならホーム画面にリダイレクト
    ref.listen<AuthState>(authStateProvider, (previous, current) {
      if (current.status == AuthStatus.authenticated) {
        context.go('/'); // ホーム画面へリダイレクト
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // エラーメッセージ表示
              if (authState.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.red.shade100,
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // ログインフォーム
              AuthForm(
                formTitle: 'ログイン',
                buttonLabel: 'ログイン',
                isLoading: authState.status == AuthStatus.loading,
                onSubmit: (email, password) {
                  ref.read(authStateProvider.notifier).signIn(email, password);
                },
              ),

              const SizedBox(height: 16),

              // 新規登録ページへのリンク
              TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text('アカウント登録はこちら'),
              ),

              // パスワードリセットページへのリンク
              TextButton(
                onPressed: () => context.push('/reset-password'),
                child: const Text('パスワードをお忘れの方'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}