import 'package:flutter/material.dart';

enum MediaType {
  image,
  video,
  none,
}

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
  final List<String> hashtags;
  final bool hasMedia;
  final MediaType mediaType;
  final int? mediaViews;
  final bool hasLink;
  final String? linkTitle;
  final String? linkDomain;
  final String? linkImageUrl;

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
    this.hashtags = const [],
    this.hasMedia = false,
    this.mediaType = MediaType.none,
    this.mediaViews,
    this.hasLink = false,
    this.linkTitle,
    this.linkDomain,
    this.linkImageUrl,
  });
}

class TweetCard extends StatelessWidget {
  final Tweet tweet;

  const TweetCard({Key? key, required this.tweet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Liked by or Reposted by
          if (tweet.likedBy.isNotEmpty || tweet.repostedBy != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 50),
              child: Row(
                children: [
                  Icon(
                    tweet.repostedBy != null ? Icons.repeat : Icons.favorite,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tweet.repostedBy != null
                        ? '${tweet.repostedBy} Reposted'
                        : '${tweet.likedBy.join(' and ')} liked',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(tweet.user.profileImageUrl),
              ),
              const SizedBox(width: 12),

              // Tweet content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info and time
                    Row(
                      children: [
                        Text(
                          tweet.user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (tweet.user.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.verified, color: Colors.blue, size: 16),
                          ),
                        Text(
                          ' @${tweet.user.handle} · ${tweet.timeAgo}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),

                    // Tweet text
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        tweet.content,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                    // Hashtags
                    if (tweet.hashtags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                        child: Wrap(
                          spacing: 4,
                          children: tweet.hashtags.map((tag) {
                            return Text(
                              '#$tag',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Media
                    if (tweet.hasMedia)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                'https://picsum.photos/400/300',
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              if (tweet.mediaType == MediaType.video)
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              if (tweet.mediaType == MediaType.video && tweet.mediaViews != null)
                                Positioned(
                                  left: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '0:11',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    // Link preview
                    if (tweet.hasLink)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tweet.linkImageUrl != null)
                                Image.network(
                                  tweet.linkImageUrl!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (tweet.linkTitle != null)
                                      Text(
                                        tweet.linkTitle!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    if (tweet.linkDomain != null)
                                      Text(
                                        tweet.linkDomain!,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Media views
                    if (tweet.mediaType == MediaType.video && tweet.mediaViews != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                        child: Text(
                          '${tweet.mediaViews} views',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    // Tweet actions
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Comments
                          Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                formatNumber(tweet.comments),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),

                          // Reposts
                          Row(
                            children: [
                              const Icon(Icons.repeat, color: Colors.grey, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                formatNumber(tweet.reposts),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),

                          // Likes
                          Row(
                            children: [
                              Icon(
                                tweet.likes > 0 ? Icons.favorite : Icons.favorite_border,
                                color: tweet.likes > 0 ? Colors.red : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatNumber(tweet.likes),
                                style: TextStyle(
                                  color: tweet.likes > 0 ? Colors.red : Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          // Share
                          const Icon(Icons.share, color: Colors.grey, size: 18),
                        ],
                      ),
                    ),

                    // Show thread
                    if (tweet.isThread)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(tweet.user.profileImageUrl),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Show this thread',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatNumber(int number) {
    if (number >= 1000) {
      double num = number / 1000;
      return '${num.toStringAsFixed(num.truncateToDouble() == num ? 0 : 1)}K';
    }
    return number.toString();
  }
}