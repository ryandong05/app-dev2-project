import 'package:flutter/material.dart';
import '../utils/tweet_utils.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/tweet_card.dart';
import '../models/tweet.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../screens/follow_list_screen.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../widgets/report_dialog.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/comment_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();
  final FollowService _followService = FollowService();
  final ReportService _reportService = ReportService();
  List<Tweet> _tweets = [];
  List<Comment> _comments = [];
  List<Tweet> _likedTweets = [];
  User? _currentUser;
  List<User> _followers = [];
  List<User> _following = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profileUser = widget.userId != null
        ? await _authService.getUserData(widget.userId!)
        : await _authService.getCurrentUserData();
    final loggedInUser = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _currentUser = profileUser;
        _currentUserId = loggedInUser?.id;
      });
      if (profileUser != null) {
        _loadFollowersAndFollowing(profileUser.id);
        _loadTweets();
        _loadComments();
        _loadLikedTweets();
      }
    }
  }

  void _loadFollowersAndFollowing(String userId) {
    _followService.getFollowers(userId).listen((followers) {
      if (mounted) {
        setState(() {
          _followers = followers;
        });
      }
    });

    _followService.getFollowing(userId).listen((following) {
      if (mounted) {
        setState(() {
          _following = following;
        });
      }
    });
  }

  void _loadTweets() {
    _tweetService.getTweets().listen((tweets) {
      if (mounted) {
        setState(() {
          // Filter tweets to show only the current user's posts
          _tweets = tweets
              .where((tweet) => tweet.user.id == _currentUser?.id)
              .toList();
        });
      }
    });
  }

  void _loadComments() {
    // Listen to all comments made by the user
    FirebaseFirestore.instance
        .collection('comments')
        .where('user.id', isEqualTo: _currentUser?.id)
        .snapshots()
        .listen((snapshot) {
      final comments =
          snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    });
  }

  void _loadLikedTweets() {
    _tweetService.getTweets().listen((tweets) {
      if (mounted) {
        setState(() {
          _likedTweets = tweets
              .where((tweet) => tweet.likes.contains(_currentUser?.id))
              .toList();
        });
      }
    });
  }

  void _showReportDialog() async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to report')),
      );
      return;
    }

    if (currentUser.id == _currentUser!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot report yourself')),
      );
      return;
    }

    // Check if user has already reported this profile
    final hasReported = await _reportService.hasUserReported(
      currentUser.id,
      _currentUser!.id,
      ReportType.user,
    );

    if (hasReported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reported this user')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportedId: _currentUser!.id,
        type: ReportType.user,
        reportedName: _currentUser!.name,
        reporterId: currentUser.id,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.year}';
  }

  void _handleNavigation(NavBarItem item) {
    // Handle navigation based on the selected item
    switch (item) {
      case NavBarItem.home:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        );
        break;
      case NavBarItem.search:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SearchScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        );
        break;
      case NavBarItem.profile:
        // Already on profile
        break;
      case NavBarItem.notifications:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const NotificationsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        );
        break;
      case NavBarItem.settings:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SettingsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Profile picture and name (no banner)
          Padding(
            padding:
                const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _currentUser!.profileImageUrl.isNotEmpty
                        ? NetworkImage(_currentUser!.profileImageUrl)
                        : null,
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.black,
                    child: _currentUser!.profileImageUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: theme.scaffoldBackgroundColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _currentUser!.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Info
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentUserId != null &&
                    _currentUserId != _currentUser!.id)
                  ElevatedButton(
                    onPressed: _showReportDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Report User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Profile Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser!.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    if (_currentUserId != null &&
                        _currentUserId != _currentUser!.id)
                      FutureBuilder<bool>(
                        future: _followService.isFollowing(
                            _currentUserId!, _currentUser!.id),
                        builder: (context, snapshot) {
                          final isFollowing = snapshot.data ?? false;
                          return ElevatedButton(
                            onPressed: () async {
                              if (isFollowing) {
                                await _followService.unfollowUser(
                                    _currentUserId!, _currentUser!.id);
                              } else {
                                await _followService.followUser(
                                    _currentUserId!, _currentUser!.id);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? Colors.grey
                                  : theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(isFollowing ? 'Following' : 'Follow'),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: theme.textTheme.bodySmall?.color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Joined ${_formatDate(_currentUser!.createdAt)}',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowListScreen(
                              userId: _currentUser!.id,
                              showFollowers: true,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            '${_followers.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Followers',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowListScreen(
                              userId: _currentUser!.id,
                              showFollowers: false,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            '${_following.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Following',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: theme.textTheme.bodyLarge?.color,
            unselectedLabelColor: theme.textTheme.bodySmall?.color,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Posts'),
              Tab(text: 'Comments'),
              Tab(text: 'Likes'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Posts Tab
                ListView.separated(
                  itemCount: _tweets.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tweet = _tweets[index];
                    return TweetCard(tweet: tweet);
                  },
                ),

                // Comments Tab
                ListView.separated(
                  itemCount: _comments.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return CommentCard(comment: comment);
                  },
                ),

                // Likes Tab
                ListView.separated(
                  itemCount: _likedTweets.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tweet = _likedTweets[index];
                    return TweetCard(tweet: tweet);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedItem: NavBarItem.profile,
        onItemSelected: _handleNavigation,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentUser = await _authService.getCurrentUserData();
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please sign in to tweet')),
            );
            return;
          }

          TweetUtils.showTweetComposer(
            context,
            onTweet: (content, media) async {
              final newTweet = Tweet(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                user: currentUser,
                content: content,
                timeAgo: TweetUtils.formatTimeAgo(DateTime.now()),
                timestamp: DateTime.now(),
                comments: 0,
                reposts: 0,
                likes: const [],
                likedBy: const [],
                imageUrls: media,
                retweets: const [],
                replies: const [],
                hasMedia: media.isNotEmpty,
                mediaType: media.isNotEmpty ? MediaType.image : MediaType.none,
              );

              await _tweetService.addTweet(newTweet);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tweet posted successfully!')),
              );
            },
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
