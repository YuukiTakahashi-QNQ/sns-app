import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

// 現在選択されている下部ナビゲーションのインデックスを管理するProvider
final bottomNavIndexProvider = StateProvider<int>((ref) => 0); // 初期値は0 (ホーム)

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  void _onItemTapped(int index, WidgetRef ref, BuildContext context) {
    // 検索機能が未実装の場合は何もしない
    if (index == 1) return;

    ref.read(bottomNavIndexProvider.notifier).state = index;
    switch (index) {
      case 0:
        context.goNamed(AppRouteNames.HomeTimeLineScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final router = ref.watch(goRouterProvider);

    ref.listen<GoRouter>(goRouterProvider, (_, __) {
      final String location =
          router.routerDelegate.currentConfiguration.uri.toString();
      int newIndex = 0;

      // より具体的なルート判定
      if (location == '/' || location.startsWith('/HomeTimeLineScreen')) {
        newIndex = 0;
      }

      if (ref.read(bottomNavIndexProvider) != newIndex) {
        ref.read(bottomNavIndexProvider.notifier).state = newIndex;
      }
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, ref, context),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, color: Colors.grey),
            label: '検索（準備中）',
            tooltip: '検索機能は現在開発中です',
          ),
        ],
      ),
    );
  }
}
