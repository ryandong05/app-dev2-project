import 'package:flutter/material.dart';
import '../models/tweet.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';
import 'comment_card.dart';

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
  bool _isRetweeted = false;
  List<String> _likes = [];
  List<String> _retweets = [];
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likes = widget.tweet.likes;
    _retweets = widget.tweet.retweets;
    _checkIfLiked();
    _checkIfRetweeted();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

  Future<void> _checkIfRetweeted() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final hasRetweeted = await _tweetService.hasUserRetweeted(
        widget.tweet.id,
        currentUser.uid,
      );
      setState(() {
        _isRetweeted = hasRetweeted;
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

  Future<void> _handleRetweet() async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) return;

    await _tweetService.retweetTweet(widget.tweet.id, currentUser);
    setState(() {
      _isRetweeted = !_isRetweeted;
      if (_isRetweeted) {
        _retweets = [..._retweets, currentUser.id];
      } else {
        _retweets = _retweets.where((id) => id != currentUser.id).toList();
      }
    });
  }

  void _showCommentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write your comment...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (_commentController.text.trim().isEmpty) return;

                      final currentUser =
                          await _authService.getCurrentUserData();
                      if (currentUser == null) return;

                      final comment = Comment(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        tweetId: widget.tweet.id,
                        user: currentUser,
                        content: _commentController.text.trim(),
                        createdAt: DateTime.now(),
                      );

                      await _tweetService.addComment(comment);
                      _commentController.clear();
                      Navigator.pop(context);
                    },
                    child: const Text('Post Comment'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.tweet.isRetweet)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 50),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.tweet.retweetedBy} Retweeted',
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
                              onTap: () {
                                setState(() {
                                  _showComments = !_showComments;
                                });
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.repeat,
                              count: _retweets,
                              onTap: _handleRetweet,
                              color: _isRetweeted ? Colors.green : null,
                            ),
                            _buildActionButton(
                              icon:
                                  _isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
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
        ),
        if (_showComments) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Comments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _showCommentDialog,
                icon: const Icon(Icons.add_comment),
                label: const Text('Add Comment'),
              ),
            ],
          ),
          StreamBuilder<List<Comment>>(
            stream: _tweetService.getComments(widget.tweet.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading comments: ${snapshot.error}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No comments yet. Be the first to comment!'),
                );
              }

              return Column(
                children:
                    comments
                        .map(
                          (comment) => CommentCard(
                            comment: comment,
                            onDelete:
                                _authService.currentUser?.uid == comment.user.id
                                    ? () => _tweetService.deleteComment(
                                      comment.id,
                                      widget.tweet.id,
                                    )
                                    : null,
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ],
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
