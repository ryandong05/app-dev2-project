import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/follow_service.dart';
import '../services/auth_service.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final bool showFollowers;

  const FollowListScreen({
    Key? key,
    required this.userId,
    required this.showFollowers,
  }) : super(key: key);

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final FollowService _followService = FollowService();
  final AuthService _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _currentUserId = user?.id;
      });
    }
  }

  Future<void> _handleFollow(User user) async {
    if (_currentUserId == null) return;

    if (await _followService.isFollowing(_currentUserId!, user.id)) {
      await _followService.unfollowUser(_currentUserId!, user.id);
    } else {
      await _followService.followUser(_currentUserId!, user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showFollowers ? 'Followers' : 'Following'),
      ),
      body: StreamBuilder<List<User>>(
        stream:
            widget.showFollowers
                ? _followService.getFollowers(widget.userId)
                : _followService.getFollowing(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text(
                widget.showFollowers
                    ? 'No followers yet'
                    : 'Not following anyone yet',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user.profileImageUrl.isNotEmpty
                          ? NetworkImage(user.profileImageUrl)
                          : null,
                  child:
                      user.profileImageUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                ),
                title: Text(user.name),
                subtitle: Text('@${user.handle}'),
                trailing:
                    _currentUserId != null && _currentUserId != user.id
                        ? FutureBuilder<bool>(
                          future: _followService.isFollowing(
                            _currentUserId!,
                            user.id,
                          ),
                          builder: (context, snapshot) {
                            final isFollowing = snapshot.data ?? false;
                            return TextButton(
                              onPressed: () => _handleFollow(user),
                              child: Text(
                                isFollowing ? 'Following' : 'Follow',
                                style: TextStyle(
                                  color:
                                      isFollowing
                                          ? theme.textTheme.bodySmall?.color
                                          : Colors.blue,
                                ),
                              ),
                            );
                          },
                        )
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}
