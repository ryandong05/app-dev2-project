import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tweet.dart';
import '../models/user.dart';

class TweetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tweets';

  // Add a new tweet
  Future<void> addTweet(Tweet tweet) async {
    await _firestore.collection(_collection).doc(tweet.id).set({
      'id': tweet.id,
      'user': {
        'id': tweet.user.id,
        'name': tweet.user.name,
        'handle': tweet.user.handle,
        'profileImageUrl': tweet.user.profileImageUrl,
        'isVerified': tweet.user.isVerified,
      },
      'content': tweet.content,
      'timeAgo': tweet.timeAgo,
      'comments': tweet.comments,
      'reposts': tweet.reposts,
      'likes': tweet.likes,
      'likedBy': tweet.likedBy,
      'repostedBy': tweet.repostedBy,
      'isThread': tweet.isThread,
      'hasMedia': tweet.hasMedia,
      'mediaType': tweet.mediaType.toString(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all tweets
  Stream<List<Tweet>> getTweets() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Tweet(
              id: data['id'],
              user: User(
                id: data['user']['id'],
                name: data['user']['name'],
                handle: data['user']['handle'],
                profileImageUrl: data['user']['profileImageUrl'],
                isVerified: data['user']['isVerified'] ?? false,
              ),
              content: data['content'],
              timeAgo: data['timeAgo'],
              comments: data['comments'],
              reposts: data['reposts'],
              likes: data['likes'],
              likedBy: List<String>.from(data['likedBy'] ?? []),
              repostedBy: data['repostedBy'],
              isThread: data['isThread'] ?? false,
              hasMedia: data['hasMedia'] ?? false,
              mediaType: MediaType.values.firstWhere(
                (e) => e.toString() == data['mediaType'],
                orElse: () => MediaType.none,
              ),
            );
          }).toList();
        });
  }

  // Update tweet likes
  Future<void> updateTweetLikes(String tweetId, List<String> likedBy) async {
    await _firestore.collection(_collection).doc(tweetId).update({
      'likes': likedBy.length,
      'likedBy': likedBy,
    });
  }
}
