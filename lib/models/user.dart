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
}
