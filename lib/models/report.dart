import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart' as app_user;

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