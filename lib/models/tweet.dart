import 'user.dart';

enum MediaType { none, image, video }

class Tweet {
  final String id;
  final User user;
  final String content;
  final String timeAgo;
  final int comments;
  final int reposts;
  final int likes;
  final List<String> likedBy;
  final String? repostedBy;
  final bool isThread;
  final bool hasMedia;
  final MediaType mediaType;

  Tweet({
    required this.id,
    required this.user,
    required this.content,
    required this.timeAgo,
    this.comments = 0,
    this.reposts = 0,
    this.likes = 0,
    this.likedBy = const [],
    this.repostedBy,
    this.isThread = false,
    this.hasMedia = false,
    this.mediaType = MediaType.none,
  });
}
