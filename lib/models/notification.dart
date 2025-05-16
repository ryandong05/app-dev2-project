import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart' as app_user;

enum NotificationType {
  like,
  retweet,
  follow,
  mention,
  reply
}

class Notification {
  final String id;
  final String userId; // The user who will receive the notification
  final app_user.User fromUser; // The user who triggered the notification
  final NotificationType type;
  final String? tweetId; // For tweet-related notifications
  final String? tweetContent; // For tweet-related notifications
  final DateTime createdAt;
  final bool isRead;

  Notification({
    required this.id,
    required this.userId,
    required this.fromUser,
    required this.type,
    this.tweetId,
    this.tweetContent,
    required this.createdAt,
    this.isRead = false,
  });

  factory Notification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Notification(
      id: doc.id,
      userId: data['userId'] ?? '',
      fromUser: app_user.User.fromMap(data['fromUser'] as Map<String, dynamic>),
      type: NotificationType.values[data['type'] ?? 0],
      tweetId: data['tweetId'],
      tweetContent: data['tweetContent'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fromUser': fromUser.toMap(),
      'type': type.index,
      'tweetId': tweetId,
      'tweetContent': tweetContent,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  String get message {
    switch (type) {
      case NotificationType.like:
        return '${fromUser.name} liked your tweet';
      case NotificationType.retweet:
        return '${fromUser.name} retweeted your tweet';
      case NotificationType.follow:
        return '${fromUser.name} followed you';
      case NotificationType.mention:
        return '${fromUser.name} mentioned you in a tweet';
      case NotificationType.reply:
        return '${fromUser.name} replied to your tweet';
    }
  }
} 