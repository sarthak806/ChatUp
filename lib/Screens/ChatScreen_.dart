import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:minorproject/Models/Chat_user.dart';
import 'package:minorproject/Widgets/Message_Card.dart';
import 'package:minorproject/Widgets/TimeCapsule_Dialog.dart';
import '../API/_Apis.dart';
import '../Models/Message.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // For storing all messages
  List<Message> _list = [];
  final _textController = TextEditingController();

  // For handling emoji picker
  bool _showEmoji = false;

  // For tracking if text field has content
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);

  // Timer for checking time capsule messages
  Timer? _timeCapsuleTimer;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      _hasText.value = _textController.text.trim().isNotEmpty;
    });
    
    // Start periodic check for time capsule messages (every 30 seconds)
    _timeCapsuleTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkTimeCapsuleMessages();
    });
    
    // Initial check
    _checkTimeCapsuleMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _hasText.dispose();
    _timeCapsuleTimer?.cancel();
    super.dispose();
  }

  // Check and unlock time capsule messages
  void _checkTimeCapsuleMessages() {
    final conversationId = APIs.getConversationID(widget.user.id);
    APIs.checkAndUnlockMessages(conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0.5,
        backgroundColor: Colors.white,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: false,
        flexibleSpace: _appBar(),
      ),
      body: Stack(
        children: [
          // Main chat view
          Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: APIs.getAllMessages(widget.user),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      //if data is loading
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const Center(child: SizedBox());

                      //if some or all data is loaded then show it
                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot.data?.docs;
                        //
                        _list = data
                                ?.map((e) => Message.fromDoc(e))
                                .where((m) =>
                                    !m.deletedFor.contains(APIs.user.uid))
                                .toList() ??
                            [];

                        // Mark any incoming, unread messages as read
                        for (final m in _list) {
                          if (m.fromId != APIs.user.uid && m.read.isEmpty) {
                            APIs.markMessageAsRead(m);
                          }
                        }

                        // Schedule mood and heat meter updates after frame is built
                        if (_list.isNotEmpty) {
                          return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _list.length,
                              itemBuilder: (context, index) {
                                // Show date separator for first message or when date changes
                                bool showDateSeparator = false;
                                if (index == 0) {
                                  showDateSeparator = true;
                                } else {
                                  final prevDate =
                                      DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(_list[index - 1].sent));
                                  final currDate =
                                      DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(_list[index].sent));
                                  showDateSeparator =
                                      prevDate.day != currDate.day ||
                                          prevDate.month != currDate.month ||
                                          prevDate.year != currDate.year;
                                }

                                return Column(
                                  children: [
                                    if (showDateSeparator)
                                      _buildDateSeparator(_list[index].sent),
                                    MessageCard(
                                      message: _list[index],
                                    ),
                                  ],
                                );
                              });
                        } else {
                          return const Center(
                              child: Text(
                            'Say hii 👋',
                            style: TextStyle(fontSize: 22),
                          ));
                        }
                    }
                  },
                ),
              ),
              _chatInput(),
            ],
          ),

          // Emoji picker overlay - appears on top without affecting layout
          if (_showEmoji)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                child: SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    textEditingController: _textController,
                    config: const Config(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        print('Image selected: ${image.name}, Size: ${image.path}');

        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => WillPopScope(
              onWillPop: () async => false,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Uploading image...'),
                  ],
                ),
              ),
            ),
          );
        }

        // Send the image - use platform-aware method with timeout
        try {
          print('Starting image upload process...');
          
          await APIs.sendImageMessageXFile(widget.user, image).timeout(
            const Duration(minutes: 5),
            onTimeout: () {
              print('Upload timeout reached');
              throw TimeoutException('Image upload took too long (5 minutes)');
            },
          );
          
          print('Upload process completed, closing dialog...');
          
          // Close loading dialog
          if (mounted) {
            Navigator.pop(context);
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image sent successfully!'),
                backgroundColor: Color(0xFF25D366),
              ),
            );
          }
        } catch (e) {
          print('Error in upload: $e');
          print('Error type: ${e.runtimeType}');
          
          // Close loading dialog
          if (mounted) {
            try {
              Navigator.pop(context);
            } catch (_) {
              // Dialog might already be closed
            }
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error in _pickImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  // Show AI assistant dialog
  void _showAIAssistant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Assistant'),
        content: const Text(
            'AI features coming soon! This will help you with smart replies and message suggestions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show Time Capsule dialog
  Future<void> _showTimeCapsuleDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const TimeCapsuleDialog(),
    );

    if (result != null && result['message'] != null && result['unlockTime'] != null) {
      // Send time capsule message
      await APIs.sendTimeCapsuleMessage(
        widget.user,
        result['message']!,
        result['unlockTime']!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time Capsule message scheduled!'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
      }
    }
  }

  // Build date separator widget
  Widget _buildDateSeparator(String timestamp) {
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final DateTime now = DateTime.now();

    String dateLabel;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      dateLabel = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('dd/MM/yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE1E8ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // AppBar widget
  Widget _appBar() {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0, left: 4, right: 8),
        child: Row(
          children: [
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 24,
                )),

            //user profile picture with online indicator
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: CachedNetworkImage(
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    imageUrl: widget.user.image,
                    errorWidget: (context, url, error) =>
                        const CircleAvatar(child: Icon(CupertinoIcons.person)),
                  ),
                ),
                if (widget.user.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Name
                  Text(widget.user.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF1F1F1F),
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  // user last seen
                  Text(widget.user.isOnline ? 'Online' : 'Last seen today',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      )),
                ],
              ),
            ),

            // Video call icon
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.videocam_outlined,
                color: Color(0xFF6B7280),
                size: 26,
              ),
            ),

            // Phone call icon
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.call_outlined,
                color: Color(0xFF6B7280),
                size: 24,
              ),
            ),

            // More options menu
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF6B7280),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Send message function
  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      APIs.sendMessage(widget.user, _textController.text.trim());
      _textController.clear();
    }
  }

  // Bottom chat textfield section
  Widget _chatInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Emoji button
          IconButton(
            onPressed: () {
              setState(() {
                _showEmoji = !_showEmoji;
              });
            },
            icon: Icon(
              _showEmoji ? Icons.keyboard : Icons.sentiment_satisfied_outlined,
              color: const Color(0xFF6B7280),
              size: 26,
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                onTap: () {
                  if (_showEmoji) {
                    setState(() {
                      _showEmoji = false;
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Time Capsule button
          IconButton(
            onPressed: _showTimeCapsuleDialog,
            icon: const Icon(
              Icons.schedule,
              color: Color(0xFF6B7280),
              size: 24,
            ),
            tooltip: 'Time Capsule',
          ),

          // Attachment button
          IconButton(
            onPressed: _pickImage,
            icon: const Icon(
              Icons.attach_file,
              color: Color(0xFF6B7280),
              size: 24,
            ),
          ),

          // Camera button
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFF6B7280),
              size: 24,
            ),
          ),

          // Send button with ValueListenableBuilder to prevent screen blinking
          ValueListenableBuilder<bool>(
            valueListenable: _hasText,
            builder: (context, hasText, child) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasText
                      ? const Color(0xFF25D366)
                      : const Color(0xFF9CA3AF),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );  
  }
}
