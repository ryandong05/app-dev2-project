import 'package:flutter/material.dart';
import '../utils/tweet_utils.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/tweet_card.dart';
import '../models/tweet.dart';
import '../models/user.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();
  List<Tweet> _tweets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTweets();
  }

  void _loadTweets() {
    _tweetService.getTweets().listen((tweets) {
      setState(() {
        _tweets = tweets;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleNavigation(NavBarItem item) {
    // Handle navigation based on the selected item
    switch (item) {
      case NavBarItem.home:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case NavBarItem.search:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case NavBarItem.profile:
        // Already on profile
        break;
      case NavBarItem.notifications:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case NavBarItem.settings:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Navigation Bar
          AppNavigationBar(
            selectedItem: NavBarItem.profile,
            onItemSelected: _handleNavigation,
            showBackButton: true,
          ),

          // Profile Header
          Container(
            height: 150,
            color:
                theme.brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.black,
            child: Stack(
              children: [
                // Profile title
                const Center(
                  child: Text(
                    'Example Profile.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Profile picture
                Positioned(
                  bottom: -40,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          theme.brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.black,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: theme.scaffoldBackgroundColor,
                      ),
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
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(color: theme.dividerColor),
                foregroundColor: theme.textTheme.bodyLarge?.color,
              ),
              child: Text(
                'Edit profile',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Profile Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  '@profile',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The quick brown fox jumps over the lazy dog.',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.link, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'example.io',
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      color: theme.textTheme.bodySmall?.color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Joined September 2018',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '217',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      ' Following',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '118',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      ' Followers',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 14,
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
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Posts'),
              Tab(text: 'Posts & replies'),
              Tab(text: 'Media'),
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
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tweet = _tweets[index];
                    return TweetCard(tweet: tweet);
                  },
                ),

                // Posts & Replies Tab
                const Center(child: Text('Posts & Replies')),

                // Media Tab
                const Center(child: Text('Media')),

                // Likes Tab
                const Center(child: Text('Likes')),
              ],
            ),
          ),
        ],
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
