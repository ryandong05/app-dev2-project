import 'package:flutter/material.dart';

enum NavBarItem {
  home,
  search,
  profile,
  notifications,
  settings
}

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
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            ),

          // Navigation items
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  item: NavBarItem.home,
                ),
                _buildNavItem(
                  icon: Icons.search,
                  item: NavBarItem.search,
                ),
                _buildNavItem(
                  icon: Icons.person,
                  item: NavBarItem.profile,
                ),
                _buildNavItem(
                  icon: Icons.notifications_none,
                  item: NavBarItem.notifications,
                ),
                _buildNavItem(
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

  Widget _buildNavItem({
    required IconData icon,
    required NavBarItem item,
  }) {
    final bool isSelected = selectedItem == item;

    return GestureDetector(
      onTap: () => onItemSelected(item),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}