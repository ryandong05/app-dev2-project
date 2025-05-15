import 'package:flutter/material.dart';
import '../models/notification.dart' as app_notification;
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../widgets/notification_card.dart';
import '../widgets/app_navigation_bar.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  late Stream<List<app_notification.Notification>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _notificationService
        .getUserNotifications(_authService.currentUser?.uid ?? '');
  }

  void _handleNavigation(NavBarItem item) {
    switch (item) {
      case NavBarItem.home:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case NavBarItem.search:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        break;
      case NavBarItem.notifications:
        // Already on notifications
        break;
      case NavBarItem.profile:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
      case NavBarItem.settings:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to notification settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Notifications content
          Expanded(
            child: StreamBuilder<List<app_notification.Notification>>(
              stream: _notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text('No notifications yet'),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return NotificationCard(
                      notification: notifications[index],
                    );
                  },
                );
              },
            ),
          ),
          // Navigation bar
          AppNavigationBar(
            selectedItem: NavBarItem.notifications,
            onItemSelected: _handleNavigation,
          ),
        ],
      ),
    );
  }
}
