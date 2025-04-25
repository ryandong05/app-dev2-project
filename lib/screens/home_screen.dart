import 'package:flutter/material.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/tweet_card.dart';
import '../utils/tweet_utils.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../widgets/tweet_composer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Sample data for tweets
  final List<Tweet> _tweets = [
    Tweet(
      id: '1',
      user: User(
        id: '1',
        name: 'Martha Craig',
        handle: 'craig_love',
        profileImageUrl: 'https://randomuser.me/api/portraits/women/32.jpg',
      ),
      content:
          'UXR/UX: You can only bring one item to a remote island to assist your research of native use of tools and usability. What do you bring? #TellMeAboutYou',
      timeAgo: '12h',
      comments: 28,
      reposts: 5,
      likes: 21,
      likedBy: ['Kieron Dotson', 'Zack John'],
      isThread: true,
    ),
    Tweet(
      id: '2',
      user: User(
        id: '2',
        name: 'Maximmilian',
        handle: 'maxjacobson',
        profileImageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      ),
      content: 'Y\'all ready for this next post?',
      timeAgo: '3h',
      comments: 46,
      reposts: 18,
      likes: 363,
      likedBy: ['Zack John'],
    ),
    Tweet(
      id: '3',
      user: User(
        id: '3',
        name: 'Tabitha Potter',
        handle: 'mis_potter',
        profileImageUrl: 'https://randomuser.me/api/portraits/women/31.jpg',
        isVerified: true,
      ),
      content:
          'Kobe\'s passing is really sticking w/ me in a way I didn\'t expect.\n\nHe was an icon, the kind of person who wouldn\'t die this way. My wife compared it to Princess Di\'s accident.\n\nBut the end can happen for anyone at any time, & I can\'t help but think of anything else lately.',
      timeAgo: '14h',
      comments: 7,
      reposts: 1,
      likes: 11,
      repostedBy: 'Kieron Dotson',
    ),
    Tweet(
      id: '4',
      user: User(
        id: '4',
        name: 'karennne',
        handle: 'karennne',
        profileImageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
      ),
      content:
          'Name a show where the lead character is the worst character on the show I\'ll go first\nSabrina Spellman',
      timeAgo: '10h',
      comments: 1906,
      reposts: 1249,
      likes: 7461,
      likedBy: ['Zack John'],
    ),
  ];

  void _handleNavigation(NavBarItem item) {
    // Handle navigation based on the selected item
    switch (item) {
      case NavBarItem.home:
        // Already on home
        break;
      case NavBarItem.search:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        break;
      case NavBarItem.profile:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
      case NavBarItem.notifications:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
        break;
      case NavBarItem.settings:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }

  void _showTweetComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: TweetComposer(
              onTweet: (content, media) {
                setState(() {
                  _tweets.insert(
                    0,
                    Tweet(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      user: User(
                        id: 'current_user',
                        name: 'Current User',
                        handle: 'current_user',
                        profileImageUrl:
                            'https://randomuser.me/api/portraits/men/1.jpg',
                      ),
                      content: content,
                      timeAgo: 'now',
                      comments: 0,
                      reposts: 0,
                      likes: 0,
                      hasMedia: media.isNotEmpty,
                      mediaType:
                          media.isNotEmpty ? MediaType.image : MediaType.none,
                    ),
                  );
                });
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
          // Navigation Bar
          AppNavigationBar(
            selectedItem: NavBarItem.home,
            onItemSelected: _handleNavigation,
            showBackButton: Navigator.of(context).canPop(),
          ),

          // Tweets List
          Expanded(
            child: ListView.separated(
              itemCount: _tweets.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1, color: Theme.of(context).dividerColor),
              itemBuilder: (context, index) {
                final tweet = _tweets[index];
                return TweetCard(tweet: tweet);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTweetComposer,
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
        foregroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
