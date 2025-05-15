import 'package:flutter/material.dart';

enum NavBarItem {
  home,
  search,
  notifications,
  profile,
  settings,
}

class AppNavigationBar extends StatelessWidget {
  final NavBarItem selectedItem;
  final Function(NavBarItem) onItemSelected;
  final bool showBackButton;

  const AppNavigationBar({
    Key? key,
    required this.selectedItem,
    required this.onItemSelected,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedItem.index,
      onTap: (index) => onItemSelected(NavBarItem.values[index]),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
