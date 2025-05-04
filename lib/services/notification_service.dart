import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/notification.dart';
import '../models/user.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';
  static const String _channelKey = 'basic_channel';
  static const String _channelName = 'Basic Notifications';
  static const String _channelDescription = 'Notification channel for social interactions';

  NotificationService() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Use default icon
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        )
      ],
    );

    // Request notification permissions
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // Create a new notification
  Future<void> createNotification(Notification notification) async {
    // Store in Firestore
    await _firestore.collection(_collection).doc(notification.id).set(notification.toMap());

    // Send push notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        channelKey: _channelKey,
        title: _getNotificationTitle(notification),
        body: notification.message,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  String _getNotificationTitle(Notification notification) {
    switch (notification.type) {
      case NotificationType.like:
        return 'New Like';
      case NotificationType.retweet:
        return 'New Retweet';
      case NotificationType.follow:
        return 'New Follower';
      case NotificationType.mention:
        return 'Mention';
      case NotificationType.reply:
        return 'New Reply';
    }
  }

  // Get all notifications for a user
  Stream<List<Notification>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Notification.fromFirestore(doc))
              .toList();
        });
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Create a like notification
  Future<void> createLikeNotification(User fromUser, String tweetId, String tweetContent, String userId) async {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: NotificationType.like,
      tweetId: tweetId,
      tweetContent: tweetContent,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  // Create a retweet notification
  Future<void> createRetweetNotification(User fromUser, String tweetId, String tweetContent, String userId) async {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: NotificationType.retweet,
      tweetId: tweetId,
      tweetContent: tweetContent,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  // Create a follow notification
  Future<void> createFollowNotification(User fromUser, String userId) async {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: NotificationType.follow,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  // Create a reply notification
  Future<void> createReplyNotification(User fromUser, String tweetId, String tweetContent, String userId) async {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: NotificationType.reply,
      tweetId: tweetId,
      tweetContent: tweetContent,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  // Create a mention notification
  Future<void> createMentionNotification(User fromUser, String tweetId, String tweetContent, String userId) async {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: NotificationType.mention,
      tweetId: tweetId,
      tweetContent: tweetContent,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }
}
