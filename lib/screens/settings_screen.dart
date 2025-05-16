import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_navigation_bar.dart';
import '../models/settings_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'account_settings_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  String _name = 'Profile';
  String _handle = '@Profile';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getCurrentUserData();
    if (mounted && userData != null) {
      setState(() {
        _name = userData.name;
        _handle = '@${userData.handle}';
      });
    }
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
        // Already on settings
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Settings Title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              // Profile Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _handle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Account Setting
              _buildSettingItem(
                title: 'Account',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen(),
                    ),
                  );
                  // Reload user data when returning from account settings
                  _loadUserData();
                },
              ),

              // Notifications Setting
              _buildSettingItem(
                title: 'Notifications',
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  onChanged: (value) async {
                    settings.toggleNotifications();
                    final userData = await _authService.getCurrentUserData();
                    if (userData != null) {
                      await NotificationService().updateNotificationSettings(
                        userData.id,
                        value,
                      );
                    }
                  },
                ),
                onTap: () {},
              ),

              // General Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Text(
                  'General',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Theme Setting
              _buildSettingItem(
                title: 'Dark Mode',
                trailing: Switch(
                  value: settings.isDarkMode,
                  onChanged: (value) => settings.toggleTheme(),
                ),
                onTap: () {},
              ),

              // Logout Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Logout Button
              _buildSettingItem(
                title: 'Logout',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  }
                },
                trailing: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppNavigationBar(
            selectedItem: NavBarItem.settings,
            onItemSelected: _handleNavigation,
          ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).iconTheme.color,
                ),
          ],
        ),
      ),
    );
  }
}
