import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tweet.dart';
import '../models/user.dart';
import '../utils/tweet_utils.dart';

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
      'createdAt': FieldValue.serverTimestamp(),
      'comments': tweet.comments,
      'reposts': tweet.reposts,
      'likes': tweet.likes,
      'likedBy': tweet.likedBy,
      'repostedBy': tweet.repostedBy,
      'isThread': tweet.isThread,
      'hasMedia': tweet.hasMedia,
      'mediaType': tweet.mediaType.index,
      'imageUrls': tweet.imageUrls,
      'retweets': tweet.retweets,
      'replies': tweet.replies,
      'parentTweetId': tweet.parentTweetId,
      'isRetweet': tweet.isRetweet,
      'retweetedBy': tweet.retweetedBy,
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
            final timestamp = data['createdAt'] as Timestamp?;
            final createdAt = timestamp?.toDate() ?? DateTime.now();
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
              timeAgo: TweetUtils.formatTimeAgo(createdAt),
              timestamp: createdAt,
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
          }).toList();
        });
  }

  // Update tweet likes
  Future<void> updateTweetLikes(String tweetId, List<String> likedBy) async {
    await _firestore.collection(_collection).doc(tweetId).update({
      'likes': likedBy,
      'likedBy': likedBy,
    });
  }

  // Migrate existing tweets to use List<String> for likes
  Future<void> migrateTweets() async {
    final snapshot = await _firestore.collection(_collection).get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['likes'] is int) {
        // Convert int likes to List<String>
        await doc.reference.update({
          'likes': List<String>.filled(data['likes'], ''),
          'likedBy': List<String>.filled(data['likes'], ''),
        });
      }
    }
  }

  // Update user information across all their tweets
  Future<void> updateUserTweets(User user) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('user.id', isEqualTo: user.id)
            .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'user': {
          'id': user.id,
          'name': user.name,
          'handle': user.handle,
          'profileImageUrl': user.profileImageUrl,
          'isVerified': user.isVerified,
        },
      });
    }
    await batch.commit();
  }
}
