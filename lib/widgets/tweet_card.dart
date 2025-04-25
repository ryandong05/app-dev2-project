import 'package:flutter/material.dart';
import '../models/tweet.dart';
import '../models/user.dart';

class TweetCard extends StatelessWidget {
  final Tweet tweet;

  const TweetCard({Key? key, required this.tweet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Liked by or Reposted by
          if (tweet.likedBy.isNotEmpty || tweet.repostedBy != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 50),
              child: Row(
                children: [
                  Icon(
                    tweet.repostedBy != null ? Icons.repeat : Icons.favorite,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tweet.repostedBy != null
                        ? '${tweet.repostedBy} Reposted'
                        : '${tweet.likedBy.join(' and ')} liked',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          // Tweet content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(tweet.user.profileImageUrl),
              ),
              const SizedBox(width: 12),
              // Tweet content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    Row(
                      children: [
                        Text(
                          tweet.user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (tweet.user.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          '@${tweet.user.handle}',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· ${tweet.timeAgo}',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Tweet text
                    Text(tweet.content, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    // Tweet actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          count: tweet.comments,
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: Icons.repeat,
                          count: tweet.reposts,
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: Icons.favorite_border,
                          count: tweet.likes,
                          onTap: () {},
                        ),
                        _buildActionButton(icon: Icons.share, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    int count = 0,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20),
          if (count > 0) ...[const SizedBox(width: 4), Text(count.toString())],
        ],
      ),
    );
  }
}
