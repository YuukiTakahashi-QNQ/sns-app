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
    // GoRouterで画面遷移 (これにより下の ref.listen が発火し、Providerが同期される)
    ref.read(bottomNavIndexProvider.notifier).state = index;
    switch (index) {
      case 0:
        context.goNamed('HomeTimeLineScreen');
        break;
      case 1:
        context.goNamed('CreateTweetScreen');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final router = ref.watch(goRouterProvider); // GoRouterインスタンスを取得

    // GoRouterのルート変更を監視し、bottomNavIndexProviderを同期する
    ref.listen<GoRouter>(goRouterProvider, (_, __) {
      final String location = router.routerDelegate.currentConfiguration.uri.toString();
      int newIndex = 0; // デフォルトはホーム

      if (location.startsWith('/CreateTweetScreen')) {
        newIndex = 1;
      } else if (location.startsWith('/')) { // '/' はホーム
        newIndex = 0;
      }
      // (他のルートが増えた場合はここにも条件を追加)

      // 現在のプロバイダーの値と異なる場合のみ更新
      if (ref.read(bottomNavIndexProvider) != newIndex) {
        ref.read(bottomNavIndexProvider.notifier).state = newIndex;
      }
    });

    return Scaffold(
      body: child, // ShellRoute によって注入される子ルートの画面
      bottomNavigationBar: BottomNavigationBar(
        // type: BottomNavigationBarType.fixed, // アイテムが少ない場合は不要かも
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, ref, context),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'hoge',
          ),
        ],
      ),
    );
  }
}