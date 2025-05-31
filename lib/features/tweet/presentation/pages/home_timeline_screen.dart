import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

class HomeTimeLineScreen extends ConsumerWidget {
  const HomeTimeLineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('HomeTimeLineScreen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('This is HomeTimeLineScreen'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // HomeTimeLineScreenへメッセージ付きで遷移
                context.goNamed(
                  AppRouteNames.CreateTweetScreen,
                  queryParameters: {'message': 'Hello from HomeTimeLineScreen!'},
                );
              },
              child: const Text('Go to CreateTweetScreen (with message)'),
            ),
          ],
        ),
      ),
    );
  }
}