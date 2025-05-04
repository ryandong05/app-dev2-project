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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context,
                  NavBarItem.home,
                  Icons.home,
                  'Home',
                ),
                _buildNavItem(
                  context,
                  NavBarItem.search,
                  Icons.search,
                  'Search',
                ),
                _buildNavItem(
                  context,
                  NavBarItem.notifications,
                  Icons.notifications,
                  'Notifications',
                ),
                _buildNavItem(
                  context,
                  NavBarItem.profile,
                  Icons.person,
                  'Profile',
                ),
                _buildNavItem(
                  context,
                  NavBarItem.settings,
                  Icons.settings,
                  'Settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NavBarItem item,
    IconData icon,
    String label,
  ) {
    final isSelected = selectedItem == item;
    return GestureDetector(
      onTap: () => onItemSelected(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).iconTheme.color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
