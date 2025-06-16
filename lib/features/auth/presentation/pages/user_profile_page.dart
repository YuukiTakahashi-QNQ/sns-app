// lib/features/auth/presentation/pages/user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../../../tweet/presentation/providers/tweet_provider.dart';
import '../../../tweet/presentation/widgets/tweet_list.dart';
import '../../../tweet/domain/entities/tweet.dart';

class UserProfilePage extends ConsumerWidget {
  final String userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserIdAsync = ref.watch(currentUserIdProvider);
    final userAsync = ref.watch(userStreamProvider(userId));
    final followStateAsync = ref.watch(followStateProvider);
    final tweetsAsync = ref.watch(tweetsByAuthorStreamProvider(userId));

    // フォローステータスの変更を監視し、完了時にユーザー情報を更新する
    ref.listen<AsyncValue<void>>(followStateProvider, (previous, next) {
      if (previous is AsyncLoading && next is AsyncData) {
        // フォロー操作が完了したらユーザーデータを更新
        ref.invalidate(userStreamProvider(userId));

        // 自分のユーザー情報も更新
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId != null) {
          ref.invalidate(userStreamProvider(currentUserId));
        }
      } else if (next is AsyncError) {
        // エラー表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール')),
      body: userAsync.when(
        data:
            (user) => _buildUserProfile(
              context,
              ref,
              user,
              currentUserIdAsync,
              followStateAsync,
              tweetsAsync,
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'ユーザー情報の取得に失敗しました: $error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildUserProfile(
    BuildContext context,
    WidgetRef ref,
    User user,
    String? currentUserId,
    AsyncValue<void> followState,
    AsyncValue<List<dynamic>> tweetsAsync,
  ) {
    final isCurrentUser = currentUserId == user.id;

    // 現在のユーザー（閲覧者）の情報を取得
    bool isFollowing = false;
    if (currentUserId != null) {
      // 現在のユーザー(閲覧者)が表示中のユーザーをフォローしているか確認
      // つまり、表示中のユーザーのフォロワーリストに現在のユーザーが含まれているか確認
      isFollowing = user.followers.contains(currentUserId);
    }

    return Column(
      children: [
        // ユーザー情報部分（スクロールしない固定部分）
        _buildUserHeader(
          context,
          ref,
          user,
          isCurrentUser,
          isFollowing,
          followState,
          currentUserId,
        ),

        const Divider(height: 1),

        // ツイートタイトル
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('ツイート', style: Theme.of(context).textTheme.titleLarge),
        ),

        // ツイートリスト（残りのスペースを埋める）
        Expanded(child: _buildTweetsList(ref, tweetsAsync)),
      ],
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    WidgetRef ref,
    User user,
    bool isCurrentUser,
    bool isFollowing,
    AsyncValue<void> followState,
    String? currentUserId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザーアバターと基本情報
          Row(
            children: [
              // ユーザーアバター
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child:
                    user.photoUrl == null
                        ? Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey.shade600,
                        )
                        : null,
              ),
              const SizedBox(width: 16),

              // ユーザー情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'ユーザー',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (user.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '登録: ${DateFormatter.formatDetailDate(user.createdAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // フォロー/フォロワー数の表示
          Row(
            children: [
              _buildStatItem(context, 'フォロー中', user.followingCount.toString()),
              const SizedBox(width: 24),
              _buildStatItem(context, 'フォロワー', user.followersCount.toString()),
            ],
          ),
          const SizedBox(height: 16),

          // フォローボタン（自分のプロフィールでない場合のみ表示）
          if (!isCurrentUser)
            _buildFollowButton(
              context,
              ref,
              isFollowing,
              followState,
              currentUserId,
              user.id,
            ),
        ],
      ),
    );
  }

  Widget _buildTweetsList(
    WidgetRef ref,
    AsyncValue<List<dynamic>> tweetsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        ref.invalidate(tweetsByAuthorStreamProvider(userId));
      },
      child: tweetsAsync.when(
        data:
            (tweets) =>
                tweets.isEmpty
                    ? ListView(
                      // 空リストの場合はListViewで「ツイートはまだありません」を表示
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'ツイートはまだありません',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ),
                      ],
                    )
                    : TweetList(
                      tweets: tweets.cast<Tweet>(),
                      onRefresh: () async {
                        ref.invalidate(tweetsByAuthorStreamProvider(userId));
                      },
                    ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ツイートの取得に失敗しました',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(tweetsByAuthorStreamProvider(userId));
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    WidgetRef ref,
    bool isFollowing,
    AsyncValue<void> followState,
    String? currentUserId,
    String targetUserId,
  ) {
    final isLoading = followState is AsyncLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            currentUserId == null || isLoading
                ? null
                : () async {
                  try {
                    if (isFollowing) {
                      // フォロー解除の処理
                      await ref
                          .read(followStateProvider.notifier)
                          .unfollowUser(currentUserId, targetUserId);

                      // 成功メッセージを表示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('フォローを解除しました'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // フォロー追加の処理
                      await ref
                          .read(followStateProvider.notifier)
                          .followUser(currentUserId, targetUserId);

                      // 成功メッセージを表示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('フォローしました'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                    // フォロー/フォロー解除後にユーザーデータを更新する
                    ref.invalidate(userStreamProvider(targetUserId));
                    // 現在のユーザー情報も更新
                    ref.invalidate(userStreamProvider(currentUserId));
                  } catch (e) {
                    // エラーメッセージを表示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('エラーが発生しました: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFollowing ? Colors.white : Theme.of(context).primaryColor,
          foregroundColor:
              isFollowing ? Theme.of(context).primaryColor : Colors.white,
          side:
              isFollowing
                  ? BorderSide(color: Theme.of(context).primaryColor)
                  : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        isFollowing
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                  ),
                )
                : Text(isFollowing ? 'フォロー中' : 'フォローする'),
      ),
    );
  }
}
