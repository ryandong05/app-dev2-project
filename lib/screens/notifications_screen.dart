import 'package:flutter/material.dart';
import '../utils/tweet_utils.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/tweet_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Sample data for tweets
  final List<Tweet> _tweets = [
    Tweet(
      id: '1',
      user: User(
        id: '1',
        name: 'Mariane',
        handle: 'marianeee',
        profileImageUrl: 'https://randomuser.me/api/portraits/women/32.jpg',
      ),
      content:
          'Hey\n@theflaticon @iconmonstr @pixsellz @danielbruce_ @romanshamiin @_vect_ @glyphish !\nCheck our our new article "Top Icons Packs and Resources for Web". You are in! 😎\n👉 marianeee.com/blog/top-icons...',
      timeAgo: '1/21/20',
      comments: 7,
      reposts: 1,
      likes: 3,
      hasLink: true,
      linkTitle: 'Top Icons Packs and Resources for Web',
      linkDomain: 'flatlogic.com',
      linkImageUrl: 'https://randomuser.me/api/portraits/lego/1.jpg',
    ),
    Tweet(
      id: '2',
      user: User(
        id: '2',
        name: 'CrownList LLC',
        handle: 'crownlistllc',
        profileImageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      ),
      content:
          'Fragments Android Wireframe Kit  UX Wire was jusr featured in today\'s\ncrownlistllc.com newsletter via @pixsellz',
      timeAgo: '1/9/20',
      comments: 0,
      reposts: 0,
      likes: 0,
      hasLink: true,
      linkImageUrl: 'https://randomuser.me/api/portraits/lego/2.jpg',
    ),
  ];

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
      // Inside the build method of _NotificationsScreenState, update the floatingActionButton:
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          TweetUtils.showTweetComposer(
            context,
            onTweet: (content, media) {
              // Handle the new tweet
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Posted: $content')));
            },
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
