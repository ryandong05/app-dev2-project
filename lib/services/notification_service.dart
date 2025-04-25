import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _notificationsCollection = 'notifications';
  final String _usersCollection = 'users';

  // Send a follow notification
  Future<void> sendFollowNotification(
    String followerId,
    String followedId,
  ) async {
    // Get follower's data
    final followerDoc =
        await _firestore.collection(_usersCollection).doc(followerId).get();
    if (!followerDoc.exists) return;

    final follower = User.fromMap(followerDoc.data()!);

    // Create notification
    await _firestore.collection(_notificationsCollection).add({
      'type': 'follow',
      'userId': followedId,
      'fromUserId': followerId,
      'fromUserName': follower.name,
      'fromUserHandle': follower.handle,
      'fromUserImage': follower.profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  // Get notifications for a user
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
              'createdAt': (data['createdAt'] as Timestamp).toDate(),
            };
          }).toList();
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(_notificationsCollection)
        .doc(notificationId)
        .update({'read': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final notifications =
        await _firestore
            .collection(_notificationsCollection)
            .where('userId', isEqualTo: userId)
            .where('read', isEqualTo: false)
            .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }
}
