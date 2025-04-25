class User {
  final String id;
  final String name;
  final String handle;
  final String profileImageUrl;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.handle,
    required this.profileImageUrl,
    this.isVerified = false,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      handle: map['handle'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
    };
  }
}
