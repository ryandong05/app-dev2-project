import 'package:flutter/material.dart';

enum NavBarItem { home, search, profile, notifications, settings }

class AppNavigationBar extends StatelessWidget {
  final NavBarItem selectedItem;
  final Function(NavBarItem) onItemSelected;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppNavigationBar({
    Key? key,
    required this.selectedItem,
    required this.onItemSelected,
    this.showBackButton = true,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (showBackButton)
            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            ),

          // Navigation items
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(context, icon: Icons.home, item: NavBarItem.home),
                _buildNavItem(
                  context,
                  icon: Icons.search,
                  item: NavBarItem.search,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person,
                  item: NavBarItem.profile,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.notifications_none,
                  item: NavBarItem.notifications,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  item: NavBarItem.settings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required NavBarItem item,
  }) {
    final theme = Theme.of(context);
    final bool isSelected = selectedItem == item;

    return GestureDetector(
      onTap: () => onItemSelected(item),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200
                  : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color:
              isSelected
                  ? theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black
                  : theme.brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}
