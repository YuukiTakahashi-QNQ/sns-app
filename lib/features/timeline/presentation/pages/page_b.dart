// lib/features/sample_pages/page_b.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

class PageB extends ConsumerWidget {
  final String? message;
  const PageB({super.key, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page B')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(message ?? 'This is Page B (No message)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Page CへID付きで遷移
                context.goNamed(
                  AppRouteNames.pageC,
                  pathParameters: {'id': '456'},
                );
              },
              child: const Text('Go to Page C (with ID 456)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  // 戻れない場合はPageAへ (直接スタックされた場合など)
                  context.goNamed(AppRouteNames.pageA);
                }
              },
              child: const Text('Go Back (or to Page A)'),
            ),
          ],
        ),
      ),
    );
  }
}