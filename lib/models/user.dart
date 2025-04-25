class User {
  final String id;
  final String name;
  final String handle;
  final String profileImageUrl;
  final bool isVerified;
  final List<String> following;
  final List<String> followers;

  User({
    required this.id,
    required this.name,
    required this.handle,
    required this.profileImageUrl,
    this.isVerified = false,
    this.following = const [],
    this.followers = const [],
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      handle: map['handle'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      isVerified: map['isVerified'] ?? false,
      following: List<String>.from(map['following'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
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
    };
  }
}
