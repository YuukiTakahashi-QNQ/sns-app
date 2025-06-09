// lib/features/tweet/presentation/widgets/tweet_card.dart
import 'package:flutter/material.dart';
import '../../domain/entities/tweet.dart';
import '../../../../core/utils/date_formatter.dart';

class TweetCard extends StatelessWidget {
  final Tweet tweet;
  final VoidCallback? onTap;

  const TweetCard({super.key, required this.tweet, this.onTap});

  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey.shade200,
      backgroundImage:
          tweet.userPhotoUrl != null ? NetworkImage(tweet.userPhotoUrl!) : null,
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tweet.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                      _buildIconButton(Icons.favorite_border, '', () {}),
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
