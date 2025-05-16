import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import 'dart:developer' as developer;

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  // Submit a new report
  Future<void> submitReport(Report report) async {
    developer.log('Submitting report: ${report.id}');
    if (report.type == ReportType.post) {
      // Get post content
      final postDoc =
          await _firestore.collection('tweets').doc(report.reportedId).get();
      final postData = postDoc.data();
      if (postData == null) {
        developer.log('Post not found: ${report.reportedId}');
        throw Exception('Post not found');
      }

      // Get usernames
      final reporterDoc =
          await _firestore.collection('users').doc(report.reporterId).get();
      final reportedUserDoc = await _firestore
          .collection('users')
          .doc(postData['user']['id'])
          .get();

      if (!reporterDoc.exists || !reportedUserDoc.exists) {
        developer.log(
            'User not found: reporter=${report.reporterId}, reported=${postData['user']['id']}');
        throw Exception('User not found');
      }

      final reporterUsername = reporterDoc.data()?['handle'] ??
          reporterDoc.data()?['name'] ??
          reporterDoc.data()?['username'] ??
          'Unknown';
      final reportedUsername = reportedUserDoc.data()?['handle'] ??
          reportedUserDoc.data()?['name'] ??
          reportedUserDoc.data()?['username'] ??
          'Unknown';

      developer.log('Reporter username: $reporterUsername');
      developer.log('Reported username: $reportedUsername');

      // Create post report
      final postReport = PostReport(
        id: report.id,
        postId: report.reportedId,
        reporterId: report.reporterId,
        reportedUserId: postData['user']['id'],
        postContent: postData['content'],
        reporterUsername: reporterUsername,
        reportedUsername: reportedUsername,
        reason: report.reason,
        timestamp: report.createdAt,
      );

      developer
          .log('Saving post report to: reports/posts/reports/${report.id}');
      developer.log('Post report data: ${postReport.toMap()}');
      // Save to nested collection
      await _firestore
          .collection('reports')
          .doc('posts')
          .collection('reports')
          .doc(report.id)
          .set(postReport.toMap());
      developer.log('Post report saved successfully');
    } else {
      // Get usernames for user report
      final reporterDoc =
          await _firestore.collection('users').doc(report.reporterId).get();
      final reportedUserDoc =
          await _firestore.collection('users').doc(report.reportedId).get();

      if (!reporterDoc.exists || !reportedUserDoc.exists) {
        developer.log(
            'User not found: reporter=${report.reporterId}, reported=${report.reportedId}');
        throw Exception('User not found');
      }

      final reporterUsername = reporterDoc.data()?['handle'] ??
          reporterDoc.data()?['name'] ??
          reporterDoc.data()?['username'] ??
          'Unknown';
      final reportedUsername = reportedUserDoc.data()?['handle'] ??
          reportedUserDoc.data()?['name'] ??
          reportedUserDoc.data()?['username'] ??
          'Unknown';

      developer.log('Reporter username: $reporterUsername');
      developer.log('Reported username: $reportedUsername');

      // Create user report
      final userReport = UserReport(
        id: report.id,
        reportedUserId: report.reportedId,
        reporterId: report.reporterId,
        reportedUsername: reportedUsername,
        reporterUsername: reporterUsername,
        reason: report.reason,
        timestamp: report.createdAt,
      );

      developer
          .log('Saving user report to: reports/users/reports/${report.id}');
      developer.log('User report data: ${userReport.toMap()}');
      // Save to nested collection
      await _firestore
          .collection('reports')
          .doc('users')
          .collection('reports')
          .doc(report.id)
          .set(userReport.toMap());
      developer.log('User report saved successfully');
    }
  }

  // Get all reports for a specific type (post or user)
  Stream<List<Report>> getReportsByType(ReportType type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.index)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  // Get all reports for a specific user (either reported by or reported)
  Stream<List<Report>> getReportsForUser(String userId,
      {bool isReporter = false}) {
    return _firestore
        .collection(_collection)
        .where(isReporter ? 'reporterId' : 'reportedId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  // Get all reports with a specific status
  Stream<List<Report>> getReportsByStatus(ReportStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.index)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  // Update report status and admin notes
  Future<void> updateReportStatus(
      String reportId, ReportStatus status, String adminId,
      {String? notes}) async {
    final updates = {
      'status': status.index,
      'resolvedBy': adminId,
      'resolvedAt': FieldValue.serverTimestamp(),
    };

    if (notes != null) {
      updates['adminNotes'] = notes;
    }

    await _firestore.collection(_collection).doc(reportId).update(updates);
  }

  // Check if a user has already reported a specific post or user
  Future<bool> hasUserReported(
      String reporterId, String reportedId, ReportType type) async {
    final collection = type == ReportType.post ? 'posts' : 'users';
    developer.log(
        'Checking if user $reporterId has reported ${type == ReportType.post ? 'post' : 'user'} $reportedId');

    final snapshot = await _firestore
        .collection('reports')
        .doc(collection)
        .collection('reports')
        .where('reporterId', isEqualTo: reporterId)
        .where(type == ReportType.post ? 'postId' : 'reportedUserId',
            isEqualTo: reportedId)
        .get();

    developer.log('Found ${snapshot.docs.length} existing reports');
    return snapshot.docs.isNotEmpty;
  }

  // Get all post reports
  Stream<List<PostReport>> getPostReports() {
    developer.log('Fetching post reports');
    return _firestore
        .collection('reports')
        .doc('posts')
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      developer.log('Received ${snapshot.docs.length} post reports');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        developer.log('Raw post report data from Firestore: $data');
        final report = PostReport.fromMap(data);
        developer.log(
            'Processed post report: reporter=${report.reporterUsername}, reported=${report.reportedUsername}');
        return report;
      }).toList();
    });
  }

  // Get all user reports
  Stream<List<UserReport>> getUserReports() {
    developer.log('Fetching user reports');
    return _firestore
        .collection('reports')
        .doc('users')
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      developer.log('Received ${snapshot.docs.length} user reports');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        developer.log('Raw user report data from Firestore: $data');
        final report = UserReport.fromMap(data);
        developer.log(
            'Processed user report: reporter=${report.reporterUsername}, reported=${report.reportedUsername}');
        return report;
      }).toList();
    });
  }

  // Dismiss post report
  Future<void> dismissPostReport(String reportId) async {
    await _firestore
        .collection('reports')
        .doc('posts')
        .collection('reports')
        .doc(reportId)
        .delete();
  }

  // Dismiss user report
  Future<void> dismissUserReport(String reportId) async {
    await _firestore
        .collection('reports')
        .doc('users')
        .collection('reports')
        .doc(reportId)
        .delete();
  }

  // Delete reported post
  Future<void> deleteReportedPost(String postId) async {
    developer.log('Attempting to delete post: $postId');
    try {
      // First delete the post from tweets collection
      final postRef = _firestore.collection('tweets').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) {
        developer.log('Post not found in tweets collection: $postId');
        throw Exception('Post not found');
      }

      await postRef.delete();
      developer.log('Successfully deleted post from tweets collection');

      // Then delete all reports for this post
      final reportsSnapshot = await _firestore
          .collection('reports')
          .doc('posts')
          .collection('reports')
          .where('postId', isEqualTo: postId)
          .get();

      developer.log('Found ${reportsSnapshot.docs.length} reports to delete');
      for (var doc in reportsSnapshot.docs) {
        await doc.reference.delete();
        developer.log('Deleted report: ${doc.id}');
      }
      developer.log('Successfully deleted all reports for post: $postId');
    } catch (e) {
      developer.log('Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  // Ban reported user
  Future<void> banUser(String userId) async {
    developer.log('Attempting to ban user: $userId');
    try {
      // First get all posts by this user
      final postsSnapshot = await _firestore
          .collection('tweets')
          .where('user.id', isEqualTo: userId)
          .get();

      developer.log('Found ${postsSnapshot.docs.length} posts to delete');

      // Delete all posts and their comments
      for (var postDoc in postsSnapshot.docs) {
        // Delete all comments for this post
        final commentsSnapshot = await _firestore
            .collection('tweets')
            .doc(postDoc.id)
            .collection('comments')
            .get();

        developer.log(
            'Found ${commentsSnapshot.docs.length} comments to delete for post ${postDoc.id}');

        for (var commentDoc in commentsSnapshot.docs) {
          await commentDoc.reference.delete();
          developer.log('Deleted comment: ${commentDoc.id}');
        }

        // Delete the post
        await postDoc.reference.delete();
        developer.log('Deleted post: ${postDoc.id}');
      }

      // Delete all comments made by this user on other posts
      final allPostsSnapshot = await _firestore.collection('tweets').get();
      for (var postDoc in allPostsSnapshot.docs) {
        final userCommentsSnapshot = await _firestore
            .collection('tweets')
            .doc(postDoc.id)
            .collection('comments')
            .where('user.id', isEqualTo: userId)
            .get();

        developer.log(
            'Found ${userCommentsSnapshot.docs.length} comments by user on post ${postDoc.id}');

        for (var commentDoc in userCommentsSnapshot.docs) {
          await commentDoc.reference.delete();
          developer.log('Deleted comment: ${commentDoc.id}');
        }
      }

      // Update user document to mark as banned
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
      });
      developer.log('Updated user document to mark as banned');

      // Delete all reports for this user
      final postReportsSnapshot = await _firestore
          .collection('reports')
          .doc('posts')
          .collection('reports')
          .where('reportedUserId', isEqualTo: userId)
          .get();

      final userReportsSnapshot = await _firestore
          .collection('reports')
          .doc('users')
          .collection('reports')
          .where('reportedUserId', isEqualTo: userId)
          .get();

      developer.log(
          'Found ${postReportsSnapshot.docs.length} post reports and ${userReportsSnapshot.docs.length} user reports to delete');

      for (var doc in postReportsSnapshot.docs) {
        await doc.reference.delete();
        developer.log('Deleted post report: ${doc.id}');
      }

      for (var doc in userReportsSnapshot.docs) {
        await doc.reference.delete();
        developer.log('Deleted user report: ${doc.id}');
      }

      developer
          .log('Successfully banned user and cleaned up all their content');
    } catch (e) {
      developer.log('Error banning user: $e');
      throw Exception('Failed to ban user: $e');
    }
  }
}
