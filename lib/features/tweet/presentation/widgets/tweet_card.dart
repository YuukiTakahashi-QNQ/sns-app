// lib/features/tweet/presentation/widgets/tweet_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/tweet.dart';
import '../../data/models/tweet_model.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/debug_utils.dart';
import '../providers/tweet_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';

class TweetCard extends ConsumerWidget {
  final Tweet tweet;
  final VoidCallback? onTap;

  const TweetCard({super.key, required this.tweet, this.onTap});
  Widget _buildUserAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (tweet.userId.isNotEmpty) {
          // Navigate to user profile page
          context.goNamed(
            AppRouteNames.UserProfile,
            pathParameters: {'userId': tweet.userId},
          );
        }
      },
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade200,
        backgroundImage:
            tweet.userPhotoUrl != null
                ? NetworkImage(tweet.userPhotoUrl!)
                : null,
        child:
            tweet.userPhotoUrl == null
                ? Text(
                  tweet.userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String count, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            if (count.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                count,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButton(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isLiked =
        currentUserId != null ? tweet.isLikedBy(currentUserId) : false;
    final likeCount = tweet.likeCount;

    // ツイートIDを取得する - TweetModelからfirestoreIdを優先的に使用
    String? tweetIdStr;
    if (tweet is TweetModel) {
      final tweetModel = tweet as TweetModel;
      tweetIdStr = tweetModel.firestoreId;

      // デバッグ情報を出力
      DebugUtils.dumpTweet(tweetModel);
    }

    // firestoreIdが取得できなかった場合は通常のidを使用
    tweetIdStr ??= tweet.id?.toString();

    return InkWell(
      onTap: () async {
        if (currentUserId == null) return; // ログインしていない場合は何もしない

        // IDが無効な場合はエラーを表示して処理を中断
        if (tweetIdStr == null || tweetIdStr.isEmpty || tweetIdStr == "null") {
          DebugUtils.log(
            '無効なツイートID: $tweetIdStr, tweet.id: ${tweet.id}',
            tag: 'Like',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('いいね操作ができません。ツイートIDが無効です。'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        DebugUtils.log(
          'いいねをトグル - ツイートID: $tweetIdStr, ユーザーID: $currentUserId',
          tag: 'Like',
        );

        try {
          await ref
              .read(tweetStateProvider.notifier)
              .toggleLike(tweetIdStr, currentUserId);
          DebugUtils.log('いいねのトグルに成功しました', tag: 'Like');
        } catch (e) {
          DebugUtils.log('いいねトグル中にエラーが発生しました: $e', tag: 'Like');
          // ユーザーにエラーを通知
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('いいね操作に失敗しました: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: isLiked ? Colors.red : Colors.grey.shade600,
            ),
            if (likeCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                likeCount.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: isLiked ? Colors.red : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (tweet.userId.isNotEmpty) {
          // Navigate to user profile page
          context.goNamed(
            AppRouteNames.UserProfile,
            pathParameters: {'userId': tweet.userId},
          );
        }
      },
      child: Text(
        tweet.userName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserAvatar(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildUserInfo(context)),
                      Text(
                        DateFormatter.formatTweetDate(tweet.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(tweet.content, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(Icons.chat_bubble_outline, '', () {}),
                      _buildIconButton(Icons.repeat, '', () {}),
                      _buildLikeButton(context, ref),
                      _buildIconButton(Icons.share_outlined, '', () {}),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
