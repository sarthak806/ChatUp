import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:minorproject/API/_Apis.dart';
import 'package:minorproject/Models/Message.dart';

class MessageCard extends StatefulWidget {
  final Message message;

  const MessageCard({
    super.key,
    required this.message,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  void _handleAction(_MessageAction action) async {
    final isSender = APIs.user.uid == widget.message.fromId;
    switch (action) {
      case _MessageAction.deleteMe:
        await APIs.deleteMessageForMe(widget.message);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted for you')),
        );
        break;
      case _MessageAction.deleteEveryone:
        if (!isSender) return;
        try {
          await APIs.deleteMessageForEveryone(widget.message);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message deleted for everyone')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
        break;
      case _MessageAction.pin:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pin message (coming soon)')),
        );
        break;
      case _MessageAction.forward:
        await Clipboard.setData(ClipboardData(text: widget.message.msg));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message copied to forward')),
        );
        break;
      case _MessageAction.reply:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply tapped (coming soon)')),
        );
        break;
    }
  }

  Widget _menuButton({required bool isReceived}) {
    final isSender = APIs.user.uid == widget.message.fromId;
    return PopupMenuButton<_MessageAction>(
      padding: EdgeInsets.zero,
      iconSize: 22,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
      onSelected: _handleAction,
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: _MessageAction.deleteMe,
            child: _MenuRow(icon: Icons.delete_outline, label: 'Delete for me'),
          ),
          if (isSender)
            const PopupMenuItem(
              value: _MessageAction.deleteEveryone,
              child: _MenuRow(
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete for everyone'),
            ),
          const PopupMenuItem(
            value: _MessageAction.pin,
            child:
                _MenuRow(icon: Icons.push_pin_outlined, label: 'Pin message'),
          ),
          const PopupMenuItem(
            value: _MessageAction.forward,
            child: _MenuRow(icon: Icons.forward, label: 'Forward'),
          ),
          const PopupMenuItem(
            value: _MessageAction.reply,
            child: _MenuRow(icon: Icons.reply, label: 'Reply'),
          ),
        ];
      },
      position: isReceived ? PopupMenuPosition.over : PopupMenuPosition.over,
    );
  }

  // Format timestamp to readable time
  String _formatTime(String timestamp) {
    try {
      final int ms = int.parse(timestamp);
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  // Format unlock time for time capsule
  String _formatUnlockTime(String timestamp) {
    try {
      final int ms = int.parse(timestamp);
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  // Check if time capsule should be unlocked
  bool _isUnlockTimeReached() {
    if (!widget.message.isTimeCapsule || widget.message.status == 'unlocked') {
      return true;
    }
    try {
      final int unlockMs = int.parse(widget.message.unlockTime);
      final DateTime unlockTime = DateTime.fromMillisecondsSinceEpoch(unlockMs);
      return DateTime.now().isAfter(unlockTime);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return APIs.user.uid == widget.message.fromId
        ? _greenMessage()
        : _blueMessage();
  }

// Sender message (received)
  Widget _blueMessage() {
    bool isHovered = false;
    final bool isLocked = widget.message.isTimeCapsule && 
                          widget.message.status == 'locked' && 
                          !_isUnlockTimeReached();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 3, left: 8, right: 60, top: 3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: StatefulBuilder(builder: (context, setState) {
          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: GestureDetector(
              child: widget.message.type == Type.image && !isLocked
                  ? _buildImageWidget(widget.message.msg, isReceived: true)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLocked 
                          ? const Color(0xFFFFF4E6) 
                          : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLocked) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9800).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.lock_clock,
                                    color: Color(0xFFFF9800),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Time Capsule Message',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF9800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Unlocks on ${_formatUnlockTime(widget.message.unlockTime)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6B7280),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else ...[
                            if (widget.message.isTimeCapsule)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_open,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Time Capsule Unlocked',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              widget.message.msg,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: const Color(0xFF1F1F1F),
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(widget.message.sent),
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

// Account holder message (sent)
  Widget _greenMessage() {
    bool isHovered = false;
    final bool isLocked = widget.message.isTimeCapsule && 
                          widget.message.status == 'locked' && 
                          !_isUnlockTimeReached();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 3, right: 8, left: 60, top: 3),
      child: Align(
        alignment: Alignment.centerRight,
        child: StatefulBuilder(builder: (context, setState) {
          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: GestureDetector(
              child: widget.message.type == Type.image && !isLocked
                  ? _buildImageWidget(widget.message.msg, isReceived: false)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLocked 
                          ? const Color(0xFFFFF4E6) 
                          : const Color(0xFFDCF8C6),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(2),
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isLocked) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9800).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.lock_clock,
                                    color: Color(0xFFFF9800),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Time Capsule Message',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF9800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Unlocks on ${_formatUnlockTime(widget.message.unlockTime)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6B7280),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else ...[
                            if (widget.message.isTimeCapsule)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_open,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Time Capsule Unlocked',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              widget.message.msg,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: const Color(0xFF1F1F1F),
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(widget.message.sent),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                widget.message.read.isNotEmpty
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 16,
                                color: widget.message.read.isNotEmpty
                                    ? const Color(0xFF53BDEB)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  // Build image widget for image messages
  Widget _buildImageWidget(String imageUrl, {required bool isReceived}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isReceived ? 4 : 18),
          topRight: Radius.circular(isReceived ? 18 : 4),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isReceived ? 4 : 18),
          topRight: Radius.circular(isReceived ? 18 : 4),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isReceived ? 4 : 18),
                topRight: Radius.circular(isReceived ? 18 : 4),
                bottomLeft: const Radius.circular(18),
                bottomRight: const Radius.circular(18),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isReceived ? 4 : 18),
                topRight: Radius.circular(isReceived ? 18 : 4),
                bottomLeft: const Radius.circular(18),
                bottomRight: const Radius.circular(18),
              ),
            ),
            child: const Center(
              child: Icon(Icons.error),
            ),
          ),
          fit: BoxFit.cover,
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}

enum _MessageAction {
  deleteMe,
  deleteEveryone,
  pin,
  forward,
  reply,
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ],
    );
  }
}
