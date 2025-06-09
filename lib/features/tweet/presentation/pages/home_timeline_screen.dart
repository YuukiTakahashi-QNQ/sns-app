import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/tweet_provider.dart';
import '../providers/tweet_state.dart';
import '../widgets/tweet_list.dart';

class HomeTimeLineScreen extends ConsumerWidget {
  const HomeTimeLineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 認証状態の取得
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;

    // サインアウト処理
    Future<void> handleSignOut() async {
      try {
        await ref.read(authStateProvider.notifier).signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ログアウトしました'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ログアウトに失敗しました: $e'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    // 未認証の場合はログイン画面へリダイレクト
    if (!isAuthenticated) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ツイート一覧の取得
    final tweetState = ref.watch(tweetStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'タイムライン',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // サインアウトボタン
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: handleSignOut,
            tooltip: 'ログアウト',
          ),
          // プロフィールボタン
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.goNamed(AppRouteNames.Profile),
            tooltip: 'プロフィール',
          ),
          // ツイート作成ボタン
          IconButton(
            icon: const Icon(Icons.add),
            color: Theme.of(context).primaryColor,
            onPressed: () => context.goNamed(AppRouteNames.CreateTweetScreen),
            tooltip: '新規ツイート',
          ),
        ],
      ),
      body: SafeArea(
        child:
            tweetState.status == TweetStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : TweetList(
                  tweets: tweetState.tweets,
                  isLoading: false,
                  errorMessage: tweetState.errorMessage,
                  onRefresh:
                      () => ref.read(tweetStateProvider.notifier).fetchTweets(),
                ),
      ),
      // ツイート作成の浮動ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed(AppRouteNames.CreateTweetScreen),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
