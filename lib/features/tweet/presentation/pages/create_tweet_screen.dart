import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

class CreateTweetScreen extends ConsumerWidget {
  final String? message;
  const CreateTweetScreen({super.key, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tweets = List.generate(20, (i) => 'ツイート $i');

    return Scaffold(
      appBar: AppBar(title: const Text('CreateTweetScreen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(message ?? 'This is CreateTweetScreen (No message)'),
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
            const SizedBox(height: 20),

            // ツイート一覧を表示
            Expanded(
              child: ListView.builder(
                itemCount: tweets.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(tweets[index]),
                    onTap: () {
                      // ツイートをタップしたときの処理
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped on ${tweets[index]}')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}