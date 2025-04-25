import 'package:flutter/material.dart';
import '../models/tweet.dart';
import '../models/user.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';

class TweetCard extends StatefulWidget {
  final Tweet tweet;

  const TweetCard({Key? key, required this.tweet}) : super(key: key);

  @override
  State<TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends State<TweetCard> {
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;
  List<String> _likes = [];

  @override
  void initState() {
    super.initState();
    _likes = widget.tweet.likes;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final hasLiked = await _tweetService.hasUserLikedTweet(
        widget.tweet.id,
        currentUser.uid,
      );
      setState(() {
        _isLiked = hasLiked;
      });
    }
  }

  Future<void> _handleLike() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    await _tweetService.likeTweet(widget.tweet.id, currentUser.uid);
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likes = [..._likes, currentUser.uid];
      } else {
        _likes = _likes.where((id) => id != currentUser.uid).toList();
      }
    });
  }

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
          if (widget.tweet.likedBy.isNotEmpty ||
              widget.tweet.repostedBy != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 50),
              child: Row(
                children: [
                  Icon(
                    widget.tweet.repostedBy != null
                        ? Icons.repeat
                        : Icons.favorite,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.tweet.repostedBy != null
                        ? '${widget.tweet.repostedBy} Reposted'
                        : '${widget.tweet.likedBy.join(' and ')} liked',
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
                backgroundImage: NetworkImage(
                  widget.tweet.user.profileImageUrl,
                ),
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
                          widget.tweet.user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (widget.tweet.user.isVerified)
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
                          '@${widget.tweet.user.handle}',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· ${widget.tweet.timeAgo}',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Tweet text
                    Text(
                      widget.tweet.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    // Tweet actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          count: widget.tweet.replies,
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: Icons.repeat,
                          count: widget.tweet.retweets,
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon:
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                          count: _likes,
                          onTap: _handleLike,
                          color: _isLiked ? Colors.red : null,
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
    List<String> count = const [],
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(count.length.toString(), style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
