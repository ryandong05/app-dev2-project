import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/notification_service.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final String _usersCollection = 'users';

  // Follow a user
  Future<void> followUser(String followerId, String followedId) async {
    // Get user data
    final followerDoc = await _firestore.collection('users').doc(followerId).get();
    final followedDoc = await _firestore.collection('users').doc(followedId).get();

    if (!followerDoc.exists || !followedDoc.exists) return;

    final follower = User.fromMap(followerDoc.data()!);
    final followed = User.fromMap(followedDoc.data()!);

    // Update follower's following list
    final followerFollowing = List<String>.from(follower.following);
    if (!followerFollowing.contains(followedId)) {
      followerFollowing.add(followedId);
      await _firestore.collection('users').doc(followerId).update({
        'following': followerFollowing,
      });
    }

    // Update followed's followers list
    final followedFollowers = List<String>.from(followed.followers);
    if (!followedFollowers.contains(followerId)) {
      followedFollowers.add(followerId);
      await _firestore.collection('users').doc(followedId).update({
        'followers': followedFollowers,
      });

      // Create follow notification
      await _notificationService.createFollowNotification(follower, followedId);
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String followerId, String followedId) async {
    // Get user data
    final followerDoc = await _firestore.collection('users').doc(followerId).get();
    final followedDoc = await _firestore.collection('users').doc(followedId).get();

    if (!followerDoc.exists || !followedDoc.exists) return;

    final follower = User.fromMap(followerDoc.data()!);
    final followed = User.fromMap(followedDoc.data()!);

    // Update follower's following list
    final followerFollowing = List<String>.from(follower.following);
    followerFollowing.remove(followedId);
    await _firestore.collection('users').doc(followerId).update({
      'following': followerFollowing,
    });

    // Update followed's followers list
    final followedFollowers = List<String>.from(followed.followers);
    followedFollowers.remove(followerId);
    await _firestore.collection('users').doc(followedId).update({
      'followers': followedFollowers,
    });
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
