import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

class CreateTweetScreen extends ConsumerWidget {
  final String? message;
  const CreateTweetScreen({super.key, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('CreateTweetScreen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(message ?? 'This is CreateTweetScreen (No message)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
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
                  context.goNamed(AppRouteNames.CreateTweetScreen);
                }
              },
              child: const Text('Go Back (or to HomeTimeLineScreen)'),
            ),
          ],
        ),
      ),
    );
  }
}