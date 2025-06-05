// lib/features/auth/presentation/pages/sign_up_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_form.dart';

class SignUpPage extends ConsumerWidget {
  const SignUpPage({super.key});

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
        title: const Text('新規登録'),
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

              // 登録フォーム
              AuthForm(
                formTitle: '新規登録',
                buttonLabel: '登録する',
                isLoading: authState.status == AuthStatus.loading,
                onSubmit: (email, password) {
                  ref.read(authStateProvider.notifier).signUp(email, password);
                },
              ),

              const SizedBox(height: 16),

              // ログインページへのリンク
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('既にアカウントをお持ちの方はこちら'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}