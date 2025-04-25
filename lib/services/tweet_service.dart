import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tweet.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../utils/tweet_utils.dart';
import 'dart:async';

class TweetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tweets';
  final String _commentsCollection = 'comments';

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
    // Create a stream controller to merge multiple streams
    final controller = StreamController<List<Tweet>>();

    // Keep track of all subscriptions
    final subscriptions = <StreamSubscription>[];

    // Listen to original tweets
    final originalTweetsSubscription = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
          try {
            List<Tweet> allTweets = [];

            // Process each document
            for (var doc in snapshot.docs) {
              final data = doc.data();
              final timestamp = data['createdAt'] as Timestamp?;
              final createdAt = timestamp?.toDate() ?? DateTime.now();

              // Get user info for each like
              List<String> likedByNames = [];
              if (data['likedBy'] != null) {
                likedByNames = List<String>.from(data['likedBy']);
              }

              final tweet = Tweet(
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
                likedBy: likedByNames,
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

              allTweets.add(tweet);
            }

            // Sort tweets by timestamp
            allTweets.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            // Add tweets to stream
            controller.add(allTweets);
          } catch (e) {
            controller.addError(e);
          }
        });

    subscriptions.add(originalTweetsSubscription);

    // When the stream is cancelled, clean up subscriptions
    controller.onCancel = () {
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
    };

    return controller.stream;
  }

  // Update tweet likes
  Future<void> updateTweetLikes(String tweetId, List<String> likedBy) async {
    await _firestore.collection(_collection).doc(tweetId).update({
      'likes': likedBy,
      'likedBy': likedBy,
    });
  }

  // Like a tweet
  Future<void> likeTweet(String tweetId, String userId) async {
    final doc = await _firestore.collection(_collection).doc(tweetId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final isRetweet = data['isRetweet'] ?? false;
    final parentTweetId = data['parentTweetId'];

    // Get user info for likedBy
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName =
        userDoc.exists ? userDoc.data()!['name'] ?? 'Anonymous' : 'Anonymous';

    // Start a batch write
    final batch = _firestore.batch();

    // If this is a retweet, we'll work with the original tweet first
    if (isRetweet && parentTweetId != null) {
      final originalDoc =
          await _firestore.collection(_collection).doc(parentTweetId).get();
      if (originalDoc.exists) {
        final originalLikes = List<String>.from(
          originalDoc.data()!['likes'] ?? [],
        );
        final originalLikedBy = List<String>.from(
          originalDoc.data()!['likedBy'] ?? [],
        );

        if (originalLikes.contains(userId)) {
          // Unlike
          originalLikes.remove(userId);
          originalLikedBy.remove(userName);
        } else {
          // Like
          originalLikes.add(userId);
          originalLikedBy.add(userName);
        }

        // Update original tweet
        batch.update(originalDoc.reference, {
          'likes': originalLikes,
          'likedBy': originalLikedBy,
        });

        // Get all retweets of this tweet (including the current one)
        final retweetsQuery =
            await _firestore
                .collection(_collection)
                .where('isRetweet', isEqualTo: true)
                .where('parentTweetId', isEqualTo: parentTweetId)
                .get();

        // Update all retweets to match the original
        for (var retweetDoc in retweetsQuery.docs) {
          batch.update(retweetDoc.reference, {
            'likes': originalLikes,
            'likedBy': originalLikedBy,
          });
        }
      }
    } else {
      // This is an original tweet
      final currentLikes = List<String>.from(data['likes'] ?? []);
      final currentLikedBy = List<String>.from(data['likedBy'] ?? []);

      if (currentLikes.contains(userId)) {
        // Unlike
        currentLikes.remove(userId);
        currentLikedBy.remove(userName);
      } else {
        // Like
        currentLikes.add(userId);
        currentLikedBy.add(userName);
      }

      // Update original tweet
      batch.update(doc.reference, {
        'likes': currentLikes,
        'likedBy': currentLikedBy,
      });

      // Get and update all retweets of this tweet
      final retweetsQuery =
          await _firestore
              .collection(_collection)
              .where('isRetweet', isEqualTo: true)
              .where('parentTweetId', isEqualTo: tweetId)
              .get();

      for (var retweetDoc in retweetsQuery.docs) {
        batch.update(retweetDoc.reference, {
          'likes': currentLikes,
          'likedBy': currentLikedBy,
        });
      }
    }

    // Commit all updates in a single batch
    await batch.commit();
  }

  // Check if a user has liked a tweet
  Future<bool> hasUserLikedTweet(String tweetId, String userId) async {
    final doc = await _firestore.collection(_collection).doc(tweetId).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final currentLikes = List<String>.from(data['likes'] ?? []);

    // If this is a retweet, check the original tweet's likes
    final isRetweet = data['isRetweet'] ?? false;
    final parentTweetId = data['parentTweetId'];

    if (isRetweet && parentTweetId != null) {
      final originalDoc =
          await _firestore.collection(_collection).doc(parentTweetId).get();
      if (originalDoc.exists) {
        final originalLikes = List<String>.from(
          originalDoc.data()!['likes'] ?? [],
        );
        return originalLikes.contains(userId);
      }
    }

    return currentLikes.contains(userId);
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
    // Update tweets where user is the author
    final tweetsSnapshot =
        await _firestore
            .collection(_collection)
            .where('user.id', isEqualTo: user.id)
            .get();

    // Update retweets where user is the retweeter
    final retweetsSnapshot =
        await _firestore
            .collection(_collection)
            .where('retweetedBy', isEqualTo: user.name)
            .get();

    // Update comments by the user
    final commentsSnapshot =
        await _firestore
            .collection(_commentsCollection)
            .where('user.id', isEqualTo: user.id)
            .get();

    final batch = _firestore.batch();

    // Update authored tweets
    for (var doc in tweetsSnapshot.docs) {
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

    // Update retweets
    for (var doc in retweetsSnapshot.docs) {
      batch.update(doc.reference, {'retweetedBy': user.name});
    }

    // Update comments
    for (var doc in commentsSnapshot.docs) {
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

  // Add a new comment
  Future<void> addComment(Comment comment) async {
    // Add the comment
    await _firestore
        .collection(_commentsCollection)
        .doc(comment.id)
        .set(comment.toMap());

    // Update tweet's comment count
    await _firestore.collection(_collection).doc(comment.tweetId).update({
      'comments': FieldValue.increment(1),
    });
  }

  // Get comments for a tweet
  Stream<List<Comment>> getComments(String tweetId) {
    return _firestore
        .collection(_commentsCollection)
        .where('tweetId', isEqualTo: tweetId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Comment> comments = [];
          for (var doc in snapshot.docs) {
            comments.add(Comment.fromFirestore(doc));
          }
          // Sort comments by createdAt locally
          comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return comments;
        });
  }

  // Like/unlike a comment
  Future<void> likeComment(String commentId, String userId) async {
    final doc =
        await _firestore.collection(_commentsCollection).doc(commentId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final currentLikes = List<String>.from(data['likes'] ?? []);

    if (currentLikes.contains(userId)) {
      currentLikes.remove(userId);
    } else {
      currentLikes.add(userId);
    }

    // Get user info for likedBy
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName =
        userDoc.exists ? userDoc.data()!['name'] ?? 'Anonymous' : 'Anonymous';
    final likedBy = List<String>.from(data['likedBy'] ?? []);

    if (currentLikes.contains(userId)) {
      if (!likedBy.contains(userName)) likedBy.add(userName);
    } else {
      likedBy.remove(userName);
    }

    await _firestore.collection(_commentsCollection).doc(commentId).update({
      'likes': currentLikes,
      'likedBy': likedBy,
    });
  }

  // Delete a comment
  Future<void> deleteComment(String commentId, String tweetId) async {
    await _firestore.collection(_commentsCollection).doc(commentId).delete();

    // Decrement tweet's comment count
    await _firestore.collection(_collection).doc(tweetId).update({
      'comments': FieldValue.increment(-1),
    });
  }

  // Retweet a tweet
  Future<void> retweetTweet(String tweetId, User retweetingUser) async {
    final tweetDoc =
        await _firestore.collection(_collection).doc(tweetId).get();
    if (!tweetDoc.exists) return;

    final tweetData = tweetDoc.data()!;
    final currentRetweets = List<String>.from(tweetData['retweets'] ?? []);

    if (currentRetweets.contains(retweetingUser.id)) {
      // Undo retweet
      currentRetweets.remove(retweetingUser.id);
      await _firestore.collection(_collection).doc(tweetId).update({
        'retweets': currentRetweets,
        'reposts': FieldValue.increment(-1),
      });

      // Delete the retweet tweet - fixed query to use retweetedBy instead of user.id
      final retweetQuery =
          await _firestore
              .collection(_collection)
              .where('isRetweet', isEqualTo: true)
              .where('parentTweetId', isEqualTo: tweetId)
              .where('retweetedBy', isEqualTo: retweetingUser.name)
              .get();

      for (var doc in retweetQuery.docs) {
        await doc.reference.delete();
      }
    } else {
      // Create retweet
      currentRetweets.add(retweetingUser.id);
      await _firestore.collection(_collection).doc(tweetId).update({
        'retweets': currentRetweets,
        'reposts': FieldValue.increment(1),
      });

      // Create a new tweet that's marked as a retweet
      final originalTweet = Tweet.fromFirestore(tweetDoc);
      final retweetId = DateTime.now().millisecondsSinceEpoch.toString();

      final retweet = Tweet(
        id: retweetId,
        user: originalTweet.user,
        content: originalTweet.content,
        timeAgo: '', // Will be set by timestamp
        timestamp: DateTime.now(),
        comments: 0,
        reposts: 0,
        likes: const [], // Initialize empty likes list
        likedBy: const [], // Initialize empty likedBy list
        imageUrls: originalTweet.imageUrls,
        retweets: const [],
        replies: const [],
        isRetweet: true,
        retweetedBy: retweetingUser.name,
        parentTweetId: tweetId,
        hasMedia: originalTweet.hasMedia,
        mediaType: originalTweet.mediaType,
      );

      await addTweet(retweet);
    }
  }

  // Check if a user has retweeted a tweet
  Future<bool> hasUserRetweeted(String tweetId, String userId) async {
    final doc = await _firestore.collection(_collection).doc(tweetId).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final retweets = List<String>.from(data['retweets'] ?? []);
    return retweets.contains(userId);
  }

  // Edit a tweet
  Future<void> editTweet(
    String tweetId,
    String newContent,
    List<String> newImageUrls,
  ) async {
    await _firestore.collection(_collection).doc(tweetId).update({
      'content': newContent,
      'imageUrls': newImageUrls,
      'hasMedia': newImageUrls.isNotEmpty,
      'mediaType':
          newImageUrls.isNotEmpty
              ? MediaType.image.index
              : MediaType.none.index,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a tweet
  Future<void> deleteTweet(String tweetId) async {
    // Delete the tweet
    await _firestore.collection(_collection).doc(tweetId).delete();

    // Delete all comments associated with this tweet
    final commentsSnapshot =
        await _firestore
            .collection(_commentsCollection)
            .where('tweetId', isEqualTo: tweetId)
            .get();

    final batch = _firestore.batch();
    for (var doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
