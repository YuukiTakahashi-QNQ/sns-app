import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../providers/trend_provider.dart';

class CreateTweetScreen extends ConsumerWidget {
  final String? message;
  const CreateTweetScreen({super.key, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(trendListProvider);

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
            // APIから取得したツイート一覧
            Expanded(
              child: trendsAsync.when(
                data: (trends) => ListView.builder(
                  itemCount: trends.length,
                  itemBuilder: (context, index) {
                    final trend = trends[index];
                    return ListTile(
                      title: Text(trend.title),
                      subtitle: Text('投稿数: ${trend.postCount}'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped on ${trend.title}')),
                        );
                      },
                    );
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('エラー: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}