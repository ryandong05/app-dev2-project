import 'package:flutter/material.dart';

class TweetComposer extends StatefulWidget {
  final Function(String, List<String>)? onTweet;

  const TweetComposer({
    Key? key,
    this.onTweet,
  }) : super(key: key);

  @override
  State<TweetComposer> createState() => _TweetComposerState();
}

class _TweetComposerState extends State<TweetComposer> {
  final TextEditingController _tweetController = TextEditingController();
  final List<String> _selectedMedia = [];
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
        widget.onTweet!(_tweetController.text, _selectedMedia);
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
    });
  }

  void _addMedia() {
    // This would typically open a media picker
    // For now, we'll just add a placeholder
    setState(() {
      _selectedMedia.add('https://picsum.photos/400/300?random=${_selectedMedia.length}');
    });
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int remainingChars = _maxCharacters - _tweetController.text.length;
    final bool isOverLimit = remainingChars < 0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      color: Colors.white,
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isOverLimit || _tweetController.text.trim().isEmpty || _isLoading
                      ? null
                      : _handleTweet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Post'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tweet Composer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),

                // Text Field
                Expanded(
                  child: TextField(
                    controller: _tweetController,
                    maxLines: 5,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: "What's happening?",
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

          // Media Preview
          if (_selectedMedia.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedMedia.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _selectedMedia[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeMedia(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Media options
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image, color: Colors.blue),
                      onPressed: _addMedia,
                    ),
                    IconButton(
                      icon: const Icon(Icons.gif_box, color: Colors.blue),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.bar_chart, color: Colors.blue),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions, color: Colors.blue),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.schedule, color: Colors.blue),
                      onPressed: () {},
                    ),
                  ],
                ),

                // Character counter
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOverLimit ? Colors.red : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      remainingChars.toString(),
                      style: TextStyle(
                        color: isOverLimit ? Colors.red : Colors.grey,
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