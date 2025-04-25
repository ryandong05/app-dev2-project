import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'notification_service.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final String _usersCollection = 'users';

  // Follow a user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    final batch = _firestore.batch();

    // Add target user to current user's following list
    final currentUserRef = _firestore
        .collection(_usersCollection)
        .doc(currentUserId);
    batch.update(currentUserRef, {
      'following': FieldValue.arrayUnion([targetUserId]),
    });

    // Add current user to target user's followers list
    final targetUserRef = _firestore
        .collection(_usersCollection)
        .doc(targetUserId);
    batch.update(targetUserRef, {
      'followers': FieldValue.arrayUnion([currentUserId]),
    });

    await batch.commit();

    // Send follow notification
    await _notificationService.sendFollowNotification(
      currentUserId,
      targetUserId,
    );
  }

  // Unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final batch = _firestore.batch();

    // Remove target user from current user's following list
    final currentUserRef = _firestore
        .collection(_usersCollection)
        .doc(currentUserId);
    batch.update(currentUserRef, {
      'following': FieldValue.arrayRemove([targetUserId]),
    });

    // Remove current user from target user's followers list
    final targetUserRef = _firestore
        .collection(_usersCollection)
        .doc(targetUserId);
    batch.update(targetUserRef, {
      'followers': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
  }

  // Check if current user is following target user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final userDoc =
        await _firestore.collection(_usersCollection).doc(currentUserId).get();
    if (!userDoc.exists) return false;

    final following = List<String>.from(userDoc.data()?['following'] ?? []);
    return following.contains(targetUserId);
  }

  // Get list of users that current user is following
  Stream<List<User>> getFollowing(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) return [];

          final followingIds = List<String>.from(
            doc.data()?['following'] ?? [],
          );
          if (followingIds.isEmpty) return [];

          final followingDocs = await Future.wait(
            followingIds.map(
              (id) => _firestore.collection(_usersCollection).doc(id).get(),
            ),
          );

          return followingDocs
              .where((doc) => doc.exists)
              .map((doc) => User.fromMap(doc.data()!))
              .toList();
        });
  }

  // Get list of users that are following current user
  Stream<List<User>> getFollowers(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) return [];

          final followerIds = List<String>.from(doc.data()?['followers'] ?? []);
          if (followerIds.isEmpty) return [];

          final followerDocs = await Future.wait(
            followerIds.map(
              (id) => _firestore.collection(_usersCollection).doc(id).get(),
            ),
          );

          return followerDocs
              .where((doc) => doc.exists)
              .map((doc) => User.fromMap(doc.data()!))
              .toList();
        });
  }
}
