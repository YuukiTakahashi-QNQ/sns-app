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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ツイートを投稿しました！'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // タイムラインに戻る
          context.goNamed(AppRouteNames.HomeTimeLineScreen);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ツイート投稿エラー: $e'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.goNamed(AppRouteNames.HomeTimeLineScreen),
        ),
        title: const Text(
          '新規ツイート',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTweet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('ツイート'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (widget.message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    widget.message!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: _tweetController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'いまどうしてる？',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                  autofocus: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
