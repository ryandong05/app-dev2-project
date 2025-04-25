import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_navigation_bar.dart';
import '../models/settings_model.dart';
import '../services/auth_service.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  String _username = '@Profile';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = await _authService.getCurrentUsername();
    if (mounted) {
      setState(() {
        _username = '@${username ?? 'Profile'}';
      });
    }
  }

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

  void _showLanguageDialog(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('English'),
                  onTap: () {
                    settings.setLanguage('English');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('French'),
                  onTap: () {
                    settings.setLanguage('French');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                child: Text(
                  _username,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
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
                  // Reload username when returning from account settings
                  _loadUsername();
                },
              ),

              // Notifications Setting
              _buildSettingItem(
                title: 'Notifications',
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  onChanged: (value) => settings.toggleNotifications(),
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

              // Language Setting
              _buildSettingItem(
                title: 'Language',
                subtitle: settings.currentLanguage,
                onTap: () => _showLanguageDialog(context),
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
            ],
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
