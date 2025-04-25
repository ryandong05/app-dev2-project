import 'package:flutter/material.dart';
import '../utils/tweet_utils.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/tweet_card.dart';
import '../models/tweet.dart';
import '../models/user.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();
  List<Tweet> _tweets = [];

  @override
  void initState() {
    super.initState();
    _loadTweets();
  }

  void _loadTweets() {
    _tweetService.getTweets().listen((tweets) {
      setState(() {
        _tweets = tweets;
      });
    });
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
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case NavBarItem.notifications:
        // Already on notifications
        break;
      case NavBarItem.settings:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Navigation Bar
          AppNavigationBar(
            selectedItem: NavBarItem.notifications,
            onItemSelected: _handleNavigation,
            showBackButton: true,
          ),

          // Notifications Content
          Expanded(
            child: ListView.separated(
              itemCount: _tweets.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tweet = _tweets[index];
                return TweetCard(tweet: tweet);
              },
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
                timeAgo: '', // Will be set by TweetService
                timestamp:
                    DateTime.now(), // Will be overwritten by server timestamp
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
