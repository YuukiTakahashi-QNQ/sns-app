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
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),

                // アプリ名
                Text(
                  'SNS App',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 48),

                // ログインフォーム
                AuthForm(
                  formTitle: 'ログイン',
                  buttonLabel: 'ログイン',
                  isLoading: authState.status == AuthStatus.loading,
                  onSubmit: (email, password) {
                    ref
                        .read(authStateProvider.notifier)
                        .signIn(email, password);
                  },
                ),

                const SizedBox(height: 24),

                // 新規登録ページへのリンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('アカウントをお持ちでない方は'),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text('新規登録'),
                    ),
                  ],
                ),

                // パスワードリセットリンク
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      // パスワードリセット機能（未実装）
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('パスワードリセット機能は準備中です'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('パスワードをお忘れの方'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
