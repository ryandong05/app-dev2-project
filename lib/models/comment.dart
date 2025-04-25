import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart' as app_user;

class Comment {
  final String id;
  final String tweetId;
  final app_user.User user;
  final String content;
  final DateTime createdAt;
  final List<String> likes;
  final List<String> likedBy;

  Comment({
    required this.id,
    required this.tweetId,
    required this.user,
    required this.content,
    required this.createdAt,
    this.likes = const [],
    this.likedBy = const [],
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      tweetId: data['tweetId'] ?? '',
      user: app_user.User.fromMap(data['user'] as Map<String, dynamic>),
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tweetId': tweetId,
      'user': user.toMap(),
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'likedBy': likedBy,
    };
  }
}
