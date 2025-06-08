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
    // 認証状態の監視
    final authState = ref.watch(authStateProvider);

    // 認証状態を監視し、認証済みならホーム画面にリダイレクト
    ref.listen<AuthState>(authStateProvider, (previous, current) {
      if (current.status == AuthStatus.authenticated) {
        context.go('/'); // ホーム画面へリダイレクト
      }

      // エラーが発生した場合はスナックバーでエラーメッセージを表示
      if (current.status == AuthStatus.error && current.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.errorMessage!),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // アプリロゴ
                Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),

                // アプリ名
                Text(
                  'SNS App',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 40),

                // 登録フォーム
                AuthForm(
                  formTitle: 'アカウント作成',
                  buttonLabel: '登録する',
                  isLoading: authState.status == AuthStatus.loading,
                  onSubmit: (email, password) {
                    ref
                        .read(authStateProvider.notifier)
                        .signUp(email, password);
                  },
                ),

                const SizedBox(height: 24),

                // ログインページへのリンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('既にアカウントをお持ちの方は'),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('ログイン'),
                    ),
                  ],
                ),

                // 利用規約
                const SizedBox(height: 16),
                const Text(
                  '登録することで、利用規約とプライバシーポリシーに同意したことになります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
