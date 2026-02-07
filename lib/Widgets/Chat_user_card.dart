import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:minorproject/API/_Apis.dart';
import 'package:minorproject/Models/Chat_user.dart';
import 'package:minorproject/Models/Message.dart';
import '../Screens/ChatScreen_.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  bool _isHovered = false;

  String _formatTime(String millis) {
    if (millis.isEmpty) return '';
    final time = DateTime.fromMillisecondsSinceEpoch(int.parse(millis));
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: APIs.getLastMessage(widget.user),
      builder: (context, snapshot) {
        Message? lastMsg;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          lastMsg = Message.fromDoc(snapshot.data!.docs.first);
        }

        final hasUnread = lastMsg != null &&
            lastMsg.fromId != APIs.user.uid &&
            lastMsg.read.isEmpty;

        final subtitle = lastMsg == null
            ? 'Last user message...'
            : lastMsg.type == Type.image
                ? 'Image'
                : lastMsg.msg;

        final timeLabel = lastMsg == null ? '' : _formatTime(lastMsg.sent);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(user: widget.user),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
              decoration: BoxDecoration(
                border: _isHovered
                    ? const Border(
                        left: BorderSide(
                          color: Color(0xFFE07856),
                          width: 4,
                        ),
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(width: _isHovered ? 12 : 0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CachedNetworkImage(
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      imageUrl: widget.user.image,
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFE07856),
                        child: Text(
                          widget.user.name.isNotEmpty
                              ? widget.user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _isHovered
                                      ? const Color(0xFFE07856)
                                      : const Color(0xFF2A2A2A),
                                ),
                                child: Text(
                                  widget.user.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (timeLabel.isNotEmpty)
                              Text(
                                timeLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9E9E9E),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            if (hasUnread) ...[
                              const SizedBox(width: 10),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4F9CF9),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
