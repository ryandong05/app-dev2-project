import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';
import '../utils/tweet_utils.dart';

class CommentCard extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onDelete;

  const CommentCard({Key? key, required this.comment, this.onDelete})
    : super(key: key);

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;
  List<String> _likes = [];

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likes;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      setState(() {
        _isLiked = _likes.contains(currentUser.uid);
      });
    }
  }

  Future<void> _handleLike() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    await _tweetService.likeComment(widget.comment.id, currentUser.uid);
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
    final currentUser = _authService.currentUser;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(widget.comment.user.profileImageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.comment.user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (widget.comment.user.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.blue,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      '@${widget.comment.user.handle}',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· ${TweetUtils.formatTimeAgo(widget.comment.createdAt)}',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.comment.content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: _handleLike,
                      child: Row(
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: _isLiked ? Colors.red : null,
                          ),
                          if (_likes.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              _likes.length.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (currentUser?.uid == widget.comment.user.id &&
                        widget.onDelete != null) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: widget.onDelete,
                        child: const Icon(Icons.delete_outline, size: 16),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
