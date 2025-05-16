import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart' as app_user;
import 'dart:developer' as developer;

enum ReportType { post, user }

enum ReportStatus { pending, reviewed, resolved, dismissed }

class Report {
  final String id;
  final String reporterId;
  final String reportedId; // Can be either post ID or user ID
  final ReportType type;
  final String reason;
  final String? description;
  final DateTime createdAt;
  final ReportStatus status;
  final String? adminNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.type,
    required this.reason,
    this.description,
    required this.createdAt,
    this.status = ReportStatus.pending,
    this.adminNotes,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedId: data['reportedId'] ?? '',
      type: ReportType.values[data['type'] ?? 0],
      reason: data['reason'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: ReportStatus.values[data['status'] ?? 0],
      adminNotes: data['adminNotes'],
      resolvedBy: data['resolvedBy'],
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedId': reportedId,
      'type': type.index,
      'reason': reason,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.index,
      'adminNotes': adminNotes,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}

class PostReport {
  final String id;
  final String postId;
  final String reporterId;
  final String reportedUserId;
  final String postContent;
  final String reporterUsername;
  final String reportedUsername;
  final String reason;
  final DateTime timestamp;

  PostReport({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reportedUserId,
    required this.postContent,
    required this.reporterUsername,
    required this.reportedUsername,
    required this.reason,
    required this.timestamp,
  });

  factory PostReport.fromMap(Map<String, dynamic> map) {
    developer.log('Creating PostReport from map: $map');
    return PostReport(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      postContent: map['postContent'] ?? '',
      reporterUsername: map['reporterUsername'] ?? 'Unknown User',
      reportedUsername: map['reportedUsername'] ?? 'Unknown User',
      reason: map['reason'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'postContent': postContent,
      'reporterUsername': reporterUsername,
      'reportedUsername': reportedUsername,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class UserReport {
  final String id;
  final String reportedUserId;
  final String reporterId;
  final String reportedUsername;
  final String reporterUsername;
  final String reason;
  final DateTime timestamp;

  UserReport({
    required this.id,
    required this.reportedUserId,
    required this.reporterId,
    required this.reportedUsername,
    required this.reporterUsername,
    required this.reason,
    required this.timestamp,
  });

  factory UserReport.fromMap(Map<String, dynamic> map) {
    developer.log('Creating UserReport from map: $map');
    return UserReport(
      id: map['id'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUsername: map['reportedUsername'] ?? 'Unknown User',
      reporterUsername: map['reporterUsername'] ?? 'Unknown User',
      reason: map['reason'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportedUserId': reportedUserId,
      'reporterId': reporterId,
      'reportedUsername': reportedUsername,
      'reporterUsername': reporterUsername,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
