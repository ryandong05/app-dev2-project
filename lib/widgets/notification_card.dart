import 'package:flutter/material.dart';
import '../models/notification.dart' as app_notification;
import '../services/notification_service.dart';

class NotificationCard extends StatelessWidget {
  final app_notification.Notification notification;
  final NotificationService _notificationService = NotificationService();
  final VoidCallback? onDismiss;

  NotificationCard({
    Key? key,
    required this.notification,
    this.onDismiss,
  }) : super(key: key);

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case app_notification.NotificationType.like:
        return Icons.favorite;
      case app_notification.NotificationType.retweet:
        return Icons.repeat;
      case app_notification.NotificationType.follow:
        return Icons.person_add;
      case app_notification.NotificationType.mention:
        return Icons.alternate_email;
      case app_notification.NotificationType.reply:
        return Icons.reply;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case app_notification.NotificationType.like:
        return Colors.red;
      case app_notification.NotificationType.retweet:
        return Colors.green;
      case app_notification.NotificationType.follow:
        return Colors.blue;
      case app_notification.NotificationType.mention:
        return Colors.orange;
      case app_notification.NotificationType.reply:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) async {
        // Delete the notification
        await _notificationService.deleteNotification(notification.id);
        onDismiss?.call();
      },
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await _notificationService.markAsRead(notification.id);
          }
          // TODO: Navigate to the relevant content (tweet or profile)
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? theme.cardColor
                : theme.cardColor.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(),
                  color: _getNotificationColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User profile image and name
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            notification.fromUser.profileImageUrl,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notification.fromUser.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (notification.fromUser.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Notification message
                    Text(notification.message),
                    if (notification.tweetContent != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        notification.tweetContent!,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Timestamp
                    Text(
                      '${notification.createdAt.hour}:${notification.createdAt.minute} · ${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
