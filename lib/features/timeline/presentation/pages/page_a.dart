// lib/features/sample_pages/page_a.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

class PageA extends ConsumerWidget {
  const PageA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page A')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('This is Page A'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Page Bへメッセージ付きで遷移
                context.goNamed(
                  AppRouteNames.pageB,
                  queryParameters: {'message': 'Hello from Page A!'},
                );
              },
              child: const Text('Go to Page B (with message)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Page CへID付きで遷移
                context.pushNamed( // pushNamedでスタックに追加
                  AppRouteNames.pageC,
                  pathParameters: {'id': '123'},
                );
              },
              child: const Text('Push to Page C (with ID 123)'),
            ),
          ],
        ),
      ),
    );
  }
}