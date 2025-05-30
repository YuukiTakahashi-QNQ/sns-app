// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 画面のプレースホルダ
import '../../features/timeline/presentation/pages/page_a.dart';
import '../../features/timeline/presentation/pages/page_b.dart';
import '../../features/timeline/presentation/pages/page_c.dart';

// ルート名を定数で管理
class AppRouteNames {
  static const String pageA = 'pageA';
  static const String pageB = 'pageB';
  static const String pageC = 'pageC';
}

// GoRouterインスタンスを提供するプロバイダ
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/pageA', // アプリ起動時の初期パス
    debugLogDiagnostics: true, // デバッグログを有効化 (開発中便利)

    // ルート定義
    routes: <RouteBase>[
      GoRoute(
        name: AppRouteNames.pageA,
        path: '/pageA',
        builder: (BuildContext context, GoRouterState state) {
          return const PageA();
        },
      ),
      GoRoute(
        name: AppRouteNames.pageB,
        path: '/pageB',
        builder: (BuildContext context, GoRouterState state) {
          // PageBにパラメータを渡す例 (オプション)
          final message = state.uri.queryParameters['message'];
          return PageB(message: message);
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