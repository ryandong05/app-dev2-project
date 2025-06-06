import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification.dart' as app_notification;
import '../models/user.dart';
import '../models/settings_model.dart';
import 'package:provider/provider.dart';

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  NotificationService() {
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    // Request permission for notifications
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get the token
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
  }

  // Check if notifications are enabled for a user
  Future<bool> areNotificationsEnabled(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return true; // Default to enabled if no setting found
    return userDoc.data()?['notificationsEnabled'] ?? true;
  }

  // Update notification settings for a user
  Future<void> updateNotificationSettings(String userId, bool enabled) async {
    await _firestore.collection('users').doc(userId).update({
      'notificationsEnabled': enabled,
    });
  }

  // Create a new notification
  Future<void> createNotification(
      app_notification.Notification notification) async {
    // Check if notifications are enabled for the user
    final notificationsEnabled =
        await areNotificationsEnabled(notification.userId);
    if (!notificationsEnabled) return;

    // Store in Firestore
    await _firestore
        .collection(_collection)
        .doc(notification.id)
        .set(notification.toMap());

    // Note: To send actual push notifications, you'll need to implement a server-side solution
    // using Firebase Cloud Functions or your own server that uses the Firebase Admin SDK
  }

  String _getNotificationTitle(app_notification.Notification notification) {
    switch (notification.type) {
      case app_notification.NotificationType.like:
        return 'New Like';
      case app_notification.NotificationType.retweet:
        return 'New Retweet';
      case app_notification.NotificationType.follow:
        return 'New Follower';
      case app_notification.NotificationType.mention:
        return 'Mention';
      case app_notification.NotificationType.reply:
        return 'New Reply';
    }
  }

  // Get all notifications for a user
  Stream<List<app_notification.Notification>> getUserNotifications(
      String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => app_notification.Notification.fromFirestore(doc))
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

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).delete();
  }

  // Create a like notification
  Future<void> createLikeNotification(
      User fromUser, String tweetId, String tweetContent, String userId) async {
    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: app_notification.NotificationType.like,
      tweetId: tweetId,
      tweetContent: tweetContent,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  // Create a retweet notification
  Future<void> createRetweetNotification(
      User fromUser, String tweetId, String tweetContent, String userId) async {
    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: app_notification.NotificationType.retweet,
      tweetId: tweetId,
      tweetContent: tweetContent,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  // Create a follow notification
  Future<void> createFollowNotification(User fromUser, String userId) async {
    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: app_notification.NotificationType.follow,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  // Create a reply notification
  Future<void> createReplyNotification(
      User fromUser, String tweetId, String tweetContent, String userId) async {
    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: app_notification.NotificationType.reply,
      tweetId: tweetId,
      tweetContent: tweetContent,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  // Create a mention notification
  Future<void> createMentionNotification(
      User fromUser, String tweetId, String tweetContent, String userId) async {
    final notification = app_notification.Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      fromUser: fromUser,
      type: app_notification.NotificationType.mention,
      tweetId: tweetId,
      tweetContent: tweetContent,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }
}
