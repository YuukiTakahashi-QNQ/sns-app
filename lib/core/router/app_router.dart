// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_sns_app/features/tweet/presentation/pages/create_tweet_screen.dart';

// 画面のプレースホルダ
import '../../features/tweet/presentation/pages/home_timeline_screen.dart';

import '../../features/tweet/presentation/pages/page_c.dart';

// ルート名を定数で管理
class AppRouteNames {
  static const String HomeTimeLineScreen = 'HomeTimeLineScreen';
  static const String CreateTweetScreen = 'CreateTweetScreen';
  static const String pageC = 'pageC';
}

// GoRouterインスタンスを提供するプロバイダ
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/HomeTimeLineScreen', // アプリ起動時の初期パス
    debugLogDiagnostics: true, // デバッグログを有効化 (開発中便利)

    // ルート定義
    routes: <RouteBase>[
      GoRoute(
        name: AppRouteNames.HomeTimeLineScreen,
        path: '/HomeTimeLineScreen',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeTimeLineScreen();
        },
      ),
      GoRoute(
        name: AppRouteNames.CreateTweetScreen,
        path: '/CreateTweetScreen',
        builder: (BuildContext context, GoRouterState state) {
          // PageBにパラメータを渡す例 (オプション)
          final message = state.uri.queryParameters['message'];
          return CreateTweetScreen(message: message);
        },
      ),
      GoRoute(
        name: AppRouteNames.pageC,
        path: '/pageC/:id', // パスパラメータの例
        builder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['id'];
          return PageC(id: id);
        },
      ),
    ],
    // エラーページ (任意)
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});