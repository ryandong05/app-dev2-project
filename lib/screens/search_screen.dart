import 'package:flutter/material.dart';
import '../utils/tweet_utils.dart';
import '../widgets/app_navigation_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Automatically focus the search field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
        // Already on search
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          // Search Bar
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.textTheme.bodySmall?.color,
                ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          // Search Results
          Expanded(
            child: Center(
              child: Text(
                'Search results will appear here',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedItem: NavBarItem.search,
        onItemSelected: _handleNavigation,
      ),
    );
  }
}
