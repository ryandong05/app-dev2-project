import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../utils/tweet_utils.dart';
import 'user.dart' as app_user;

enum MediaType { none, image, video }

class Tweet {
  final String id;
  final app_user.User user;
  final String content;
  final String timeAgo;
  final DateTime timestamp;
  final int comments;
  final int reposts;
  final List<String> likes; // Contains user IDs who liked the tweet
  final List<String> likedBy; // Contains names of users who liked the tweet
  final String? repostedBy;
  final bool isThread;
  final bool hasMedia;
  final MediaType mediaType;
  final List<String> imageUrls;
  final List<String> retweets;
  final List<String> replies;
  final String? parentTweetId;
  final bool isRetweet;
  final String? retweetedBy;

  Tweet({
    required this.id,
    required this.user,
    required this.content,
    required this.timeAgo,
    required this.timestamp,
    this.comments = 0,
    this.reposts = 0,
    required this.likes,
    this.likedBy = const [],
    this.repostedBy,
    this.isThread = false,
    this.hasMedia = false,
    this.mediaType = MediaType.none,
    required this.imageUrls,
    required this.retweets,
    required this.replies,
    this.parentTweetId,
    this.isRetweet = false,
    this.retweetedBy,
  });

  factory Tweet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tweet(
      id: doc.id,
      user: app_user.User.fromMap(data['user'] as Map<String, dynamic>),
      content: data['content'] ?? '',
      timeAgo: data['timeAgo'] ?? '',
      timestamp: (data['createdAt'] as Timestamp).toDate(),
      comments: data['comments'] ?? 0,
      reposts: data['reposts'] ?? 0,
      likes: List<String>.from(data['likes'] ?? []),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      repostedBy: data['repostedBy'],
      isThread: data['isThread'] ?? false,
      hasMedia: data['hasMedia'] ?? false,
      mediaType: MediaType.values[data['mediaType'] ?? 0],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      retweets: List<String>.from(data['retweets'] ?? []),
      replies: List<String>.from(data['replies'] ?? []),
      parentTweetId: data['parentTweetId'],
      isRetweet: data['isRetweet'] ?? false,
      retweetedBy: data['retweetedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'content': content,
      'timeAgo': timeAgo,
      'createdAt': timestamp,
      'comments': comments,
      'reposts': reposts,
      'likes': likes,
      'likedBy': likedBy,
      'repostedBy': repostedBy,
      'isThread': isThread,
      'hasMedia': hasMedia,
      'mediaType': mediaType,
      'imageUrls': imageUrls,
      'retweets': retweets,
      'replies': replies,
      'parentTweetId': parentTweetId,
      'isRetweet': isRetweet,
      'retweetedBy': retweetedBy,
    };
  }

  String getFormattedTimeAgo() {
    return TweetUtils.formatTimeAgo(timestamp);
  }
}
