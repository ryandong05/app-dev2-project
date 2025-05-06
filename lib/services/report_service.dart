import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  // Submit a new report
  Future<void> submitReport(Report report) async {
    await _firestore.collection(_collection).doc(report.id).set(report.toMap());
  }

  // Get all reports for a specific type (post or user)
  Stream<List<Report>> getReportsByType(ReportType type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.index)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Report.fromFirestore(doc))
              .toList();
        });
  }

  // Get all reports for a specific user (either reported by or reported)
  Stream<List<Report>> getReportsForUser(String userId, {bool isReporter = false}) {
    return _firestore
        .collection(_collection)
        .where(isReporter ? 'reporterId' : 'reportedId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Report.fromFirestore(doc))
              .toList();
        });
  }

  // Get all reports with a specific status
  Stream<List<Report>> getReportsByStatus(ReportStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.index)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Report.fromFirestore(doc))
              .toList();
        });
  }

  // Update report status and admin notes
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status,
    String adminId,
    {String? notes}
  ) async {
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
  Future<bool> hasUserReported(String reporterId, String reportedId, ReportType type) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('reporterId', isEqualTo: reporterId)
        .where('reportedId', isEqualTo: reportedId)
        .where('type', isEqualTo: type.index)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Get all post reports
  Stream<List<PostReport>> getPostReports() {
    return _firestore
        .collection('reports')
        .doc('posts')
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PostReport.fromMap(data);
      }).toList();
    });
  }

  // Get all user reports
  Stream<List<UserReport>> getUserReports() {
    return _firestore
        .collection('reports')
        .doc('users')
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserReport.fromMap(data);
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
    // First delete the post
    await _firestore.collection('posts').doc(postId).delete();
    
    // Then delete all reports for this post
    final reportsSnapshot = await _firestore
        .collection('reports')
        .doc('posts')
        .collection('reports')
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in reportsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Ban reported user
  Future<void> banUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isBanned': true,
      'bannedAt': FieldValue.serverTimestamp(),
    });

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

    for (var doc in postReportsSnapshot.docs) {
      await doc.reference.delete();
    }

    for (var doc in userReportsSnapshot.docs) {
      await doc.reference.delete();
    }
  }
} 