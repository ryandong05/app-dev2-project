import 'package:flutter/material.dart';
import '../widgets/tweet_composer.dart';

class TweetUtils {
  static void showTweetComposer(BuildContext context, {Function(String, List<String>)? onTweet}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: TweetComposer(onTweet: onTweet),
        );
      },
    );
  }
}