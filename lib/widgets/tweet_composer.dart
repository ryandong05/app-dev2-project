import 'package:flutter/material.dart';

class TweetComposer extends StatefulWidget {
  final Function(String, List<String>)? onTweet;

  const TweetComposer({Key? key, this.onTweet}) : super(key: key);

  @override
  State<TweetComposer> createState() => _TweetComposerState();
}

class _TweetComposerState extends State<TweetComposer> {
  final TextEditingController _tweetController = TextEditingController();
  final int _maxCharacters = 280;
  bool _isLoading = false;

  @override
  void dispose() {
    _tweetController.dispose();
    super.dispose();
  }

  void _handleTweet() {
    if (_tweetController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(seconds: 1), () {
      if (widget.onTweet != null) {
        widget.onTweet!(_tweetController.text, []); // Empty media list
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int remainingChars = _maxCharacters - _tweetController.text.length;
    final bool isOverLimit = remainingChars < 0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      color: theme.cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isOverLimit ||
                          _tweetController.text.trim().isEmpty ||
                          _isLoading
                      ? null
                      : _handleTweet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    foregroundColor: theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                          ),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),

          // Tweet Composer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey,
                  child: Icon(
                    Icons.person,
                    color: theme.scaffoldBackgroundColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Text Field
                Expanded(
                  child: TextField(
                    controller: _tweetController,
                    maxLines: 5,
                    minLines: 3,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: "What's happening?",
                      hintStyle: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Character counter
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOverLimit ? Colors.red : theme.dividerColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      remainingChars.toString(),
                      style: TextStyle(
                        color: isOverLimit
                            ? Colors.red
                            : theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
