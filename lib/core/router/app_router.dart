// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_shell.dart';

// 認証関連
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';

// ツイート関連
import '../../features/tweet/presentation/pages/home_timeline_screen.dart';
import '../../features/tweet/presentation/pages/create_tweet_screen.dart';

// ルート名を定義するクラス
class AppRouteNames {
  static const String HomeTimeLineScreen = 'HomeTimeLineScreen';
  static const String CreateTweetScreen = 'CreateTweetScreen';
  static const String SignIn = 'SignIn';
  static const String SignUp = 'SignUp';
  static const String Profile = 'Profile';
}

// GoRouterインスタンスを提供するProvider
final goRouterProvider = Provider<GoRouter>((ref) {
  // 認証状態を監視
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/', // 最初に表示するパス
    redirect: (BuildContext context, GoRouterState state) {
      // 認証が必要なパスかどうかをチェック
      final String path = state.uri.path;
      final isAuthRequired =
          !path.startsWith('/login') && !path.startsWith('/signup');
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final needsDisplayName = authState.status == AuthStatus.needsDisplayName;

      // プロフィール設定が必要な状態の処理
      if (needsDisplayName) {
        // プロフィール設定ページにいない場合は設定ページへリダイレクト
        if (!path.startsWith('/profile')) {
          return '/profile';
        }
        return null;
      }

      // 認証が必要なパスで、未認証の場合はログイン画面にリダイレクト
      if (isAuthRequired && !isAuthenticated) {
        return '/login';
      }

      // 既に認証済みで、ログイン画面や新規登録画面にアクセスした場合はホーム画面にリダイレクト
      if (isAuthenticated && (path == '/login' || path == '/signup')) {
        return '/';
      }

      // それ以外はリダイレクトなし
      return null;
    },
    routes: <RouteBase>[
      // 認証関連のルート（AppShellなし）
      GoRoute(
        path: '/login',
        name: AppRouteNames.SignIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/signup',
        name: AppRouteNames.SignUp,
        builder: (context, state) => const SignUpPage(),
      ),

      // AppShell を使ったルート (下部ナビゲーションバーを持つ画面群)
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AppShell(child: child); // AppShellでラップ
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            name: AppRouteNames.HomeTimeLineScreen, // ルート名
            builder: (BuildContext context, GoRouterState state) {
              return const HomeTimeLineScreen(); // ホーム画面
            },
          ),
          GoRoute(
            path: '/create-tweet',
            name: AppRouteNames.CreateTweetScreen,
            builder: (BuildContext context, GoRouterState state) {
              final message = state.uri.queryParameters['message'];
              return CreateTweetScreen(message: message); // ツイート作成画面
            },
          ),
          GoRoute(
            path: '/profile',
            name: AppRouteNames.Profile,
            builder: (BuildContext context, GoRouterState state) {
              return const ProfilePage(); // プロフィール画面
            },
          ),
        ],
      ),
    ],
  );
});
