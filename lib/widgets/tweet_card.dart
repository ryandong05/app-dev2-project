import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tweet.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../models/report.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../utils/tweet_utils.dart';
import '../screens/profile_screen.dart';
import 'comment_card.dart';
import 'tweet_composer.dart';
import 'report_dialog.dart';

class TweetCard extends StatefulWidget {
  final Tweet tweet;
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();
  final ReportService _reportService = ReportService();

  TweetCard({Key? key, required this.tweet}) : super(key: key);

  @override
  State<TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends State<TweetCard> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  bool _isRetweeted = false;
  bool _showComments = false;
  List<String> _likes = [];
  List<String> _retweets = [];

  @override
  void initState() {
    super.initState();
    _likes = widget.tweet.likes;
    _retweets = widget.tweet.retweets;
    _checkLikeStatus();
    _checkRetweetStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkLikeStatus() async {
    final currentUser = await widget._authService.getCurrentUserData();
    if (currentUser != null) {
      setState(() {
        _isLiked = _likes.contains(currentUser.id);
      });
    }
  }

  Future<void> _checkRetweetStatus() async {
    final currentUser = await widget._authService.getCurrentUserData();
    if (currentUser != null) {
      setState(() {
        _isRetweeted = _retweets.contains(currentUser.id);
      });
    }
  }

  Future<void> _handleLike() async {
    final currentUser = await widget._authService.getCurrentUserData();
    if (currentUser == null) return;

    await widget._tweetService.likeTweet(widget.tweet.id, currentUser.id);
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likes = [..._likes, currentUser.id];
      } else {
        _likes = _likes.where((id) => id != currentUser.id).toList();
      }
    });
  }

  Future<void> _handleRetweet() async {
    final currentUser = await widget._authService.getCurrentUserData();
    if (currentUser == null) return;

    await widget._tweetService.retweetTweet(widget.tweet.id, currentUser);
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
      builder: (context) => Padding(
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
                      await widget._authService.getCurrentUserData();
                  if (currentUser == null) return;

                  final comment = Comment(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    tweetId: widget.tweet.id,
                    user: currentUser,
                    content: _commentController.text.trim(),
                    createdAt: DateTime.now(),
                  );

                  await widget._tweetService.addComment(comment);
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

  void _showEditDialog() {
    final TextEditingController _editController = TextEditingController(
      text: widget.tweet.content,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tweet'),
        content: TextField(
          controller: _editController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Edit your tweet...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_editController.text.trim().isNotEmpty) {
                await widget._tweetService.editTweet(
                  widget.tweet.id,
                  _editController.text.trim(),
                  widget.tweet.imageUrls,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tweet updated successfully!'),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tweet'),
        content: const Text('Are you sure you want to delete this tweet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await widget._tweetService.deleteTweet(widget.tweet.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tweet deleted successfully!'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() async {
    final currentUser = await widget._authService.getCurrentUserData();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to report')),
      );
      return;
    }

    // Check if user has already reported this tweet
    final hasReported = await widget._reportService.hasUserReported(
      currentUser.id,
      widget.tweet.id,
      ReportType.post,
    );

    if (hasReported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reported this post')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportedId: widget.tweet.id,
        type: ReportType.post,
        reportedName: widget.tweet.user.name,
        reporterId: currentUser.id,
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: widget.tweet.user.id,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        widget.tweet.user.profileImageUrl,
                      ),
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
                            const Spacer(),
                            if (widget.tweet.user.id ==
                                widget._authService.currentUser?.uid)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditDialog();
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation();
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            if (widget.tweet.user.id !=
                                widget._authService.currentUser?.uid)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'report') {
                                    _showReportDialog();
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'report',
                                    child: Text('Report'),
                                  ),
                                ],
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
                              count: widget.tweet.comments,
                              onTap: () {
                                setState(() {
                                  _showComments = !_showComments;
                                });
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.repeat,
                              count: _retweets.length,
                              onTap: _handleRetweet,
                              color: _isRetweeted ? Colors.green : null,
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: widget._tweetService.getTweetStream(
                                widget.tweet.id,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final data = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  final likes = List<String>.from(
                                    data['likes'] ?? [],
                                  );
                                  return _buildActionButton(
                                    icon: _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    count: likes.length,
                                    onTap: _handleLike,
                                    color: _isLiked ? Colors.red : null,
                                  );
                                }
                                return _buildActionButton(
                                  icon: _isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  count: _likes.length,
                                  onTap: _handleLike,
                                  color: _isLiked ? Colors.red : null,
                                );
                              },
                            ),
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
            stream: widget._tweetService.getComments(widget.tweet.id),
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
                children: comments
                    .map(
                      (comment) => CommentCard(
                        comment: comment,
                        onDelete: widget._authService.currentUser?.uid ==
                                comment.user.id
                            ? () => widget._tweetService.deleteComment(
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
    required VoidCallback onTap,
    Color? color,
    int count = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(color: color, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
