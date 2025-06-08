import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/tweet_provider.dart';

class CreateTweetScreen extends ConsumerStatefulWidget {
  final String? message;
  const CreateTweetScreen({super.key, this.message});

  @override
  ConsumerState<CreateTweetScreen> createState() => _CreateTweetScreenState();
}

class _CreateTweetScreenState extends ConsumerState<CreateTweetScreen> {
  final _tweetController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tweetController.dispose();
    super.dispose();
  }

  // ツイートを投稿する処理
  Future<void> _submitTweet() async {
    final content = _tweetController.text.trim();
    if (content.isEmpty) return;

    final authState = ref.read(authStateProvider);
    if (authState.status == AuthStatus.authenticated &&
        authState.user != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final tweetNotifier = ref.read(tweetStateProvider.notifier);
        await tweetNotifier.createTweet(content, authState.user!);

        if (mounted) {
          _tweetController.clear();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ツイートを投稿しました！')));
          // タイムラインに戻る
          context.goNamed(AppRouteNames.HomeTimeLineScreen);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('ツイート投稿エラー: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規ツイート作成'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitTweet,
            child: Text(
              '投稿',
              style: TextStyle(
                color: _isSubmitting ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(widget.message!),
              ),
            Expanded(
              child: TextField(
                controller: _tweetController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'いまどうしてる？',
                  border: InputBorder.none,
                ),
                autofocus: true,
              ),
            ),
            if (_isSubmitting) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
