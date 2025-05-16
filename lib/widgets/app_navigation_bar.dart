import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../models/notification.dart' as app_notification;

enum NavBarItem {
  home,
  search,
  notifications,
  profile,
  settings,
}

class AppNavigationBar extends StatefulWidget {
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
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  Stream<List<app_notification.Notification>>? _notificationsStream;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser != null && mounted) {
      setState(() {
        _notificationsStream =
            _notificationService.getUserNotifications(currentUser.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<app_notification.Notification>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _unreadCount = snapshot.data!.where((n) => !n.isRead).length;
        }

        return BottomNavigationBar(
          currentIndex: widget.selectedItem.index,
          onTap: (index) => widget.onItemSelected(NavBarItem.values[index]),
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        );
      },
    );
  }
}
