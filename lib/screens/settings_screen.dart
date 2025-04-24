import 'package:flutter/material.dart';
import '../widgets/app_navigation_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case NavBarItem.settings:
      // Already on settings
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: Column(
        children: [
          // Navigation Bar
          AppNavigationBar(
            selectedItem: NavBarItem.settings,
            onItemSelected: _handleNavigation,
            showBackButton: true,
          ),

          // Settings Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: const Text(
              'Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Profile Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFEEF2F5),
            child: const Text(
              '@Profile',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Account Setting
          _buildSettingItem(
            title: 'Account',
            onTap: () {},
          ),

          // Notifications Setting
          _buildSettingItem(
            title: 'Notifications',
            onTap: () {},
          ),

          // General Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFEEF2F5),
            child: const Text(
              'General',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Language Setting
          _buildSettingItem(
            title: 'Language',
            onTap: () {},
          ),

          // Theme Setting
          _buildSettingItem(
            title: 'Theme',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}