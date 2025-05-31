// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_shell.dart';

// 画面のプレースホルダ
import '../../features/tweet/presentation/pages/home_timeline_screen.dart';
import 'package:train_sns_app/features/tweet/presentation/pages/create_tweet_screen.dart';

// ルート名を定義するクラス
class AppRouteNames {
  static const String HomeTimeLineScreen = 'HomeTimeLineScreen';
  static const String CreateTweetScreen = 'CreateTweetScreen';
}

// GoRouterインスタンスを提供するProvider
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/', // 最初に表示するパス
    routes: <RouteBase>[
      // AppShell を使ったルート (下部ナビゲーションバーを持つ画面群)
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AppShell(child: child); // AppShellでラップ
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            name: 'HomeTimeLineScreen', // ルート名
            builder: (BuildContext context, GoRouterState state) {
              return const HomeTimeLineScreen(); // ホーム画面
            },
          ),
          GoRoute(
            path: '/CreateTweetScreen',
            name: 'CreateTweetScreen',
            builder: (BuildContext context, GoRouterState state) {
              return const CreateTweetScreen(); // 検索画面
            },
          ),
        ],
      ),
    ],
  );
});