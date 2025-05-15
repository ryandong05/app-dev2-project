import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String handle;
  final String profileImageUrl;
  final bool isVerified;
  final List<String> following;
  final List<String> followers;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.handle,
    required this.profileImageUrl,
    this.isVerified = false,
    this.following = const [],
    this.followers = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      handle: map['handle'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      isVerified: map['isVerified'] ?? false,
      following: List<String>.from(map['following'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
      'following': following,
      'followers': followers,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
