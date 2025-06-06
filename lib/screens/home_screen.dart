import 'package:flutter/material.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/tweet_card.dart' as tweet_card;
import '../utils/tweet_utils.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../widgets/tweet_composer.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';
import '../models/tweet.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();
  List<Tweet> _tweets = [];

  @override
  void initState() {
    super.initState();
    _loadTweets();
    _tweetService.migrateTweets();
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
        // Already on home
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
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ProfileScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        );
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

  void _showTweetComposer() async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in to tweet')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: TweetComposer(
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
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Content
          Expanded(
            child: ListView.builder(
              itemCount: _tweets.length,
              itemBuilder: (context, index) {
                return tweet_card.TweetCard(tweet: _tweets[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTweetComposer,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedItem: NavBarItem.home,
        onItemSelected: _handleNavigation,
      ),
    );
  }
}
