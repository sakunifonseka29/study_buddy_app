import 'package:flutter/material.dart';
import 'package:study_buddy_app/Models/chatModel.dart';
import 'package:intl/intl.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool showSender;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showSender = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Show sender name if not current user
            if (!isCurrentUser && showSender)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 2.0),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color:
                    isCurrentUser
                        ? Colors.deepPurple.shade100
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  Text(message.content, style: const TextStyle(fontSize: 16)),

                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String prefix = '';

    if (messageDate == today) {
      prefix = 'Today';
    } else if (messageDate == yesterday) {
      prefix = 'Yesterday';
    } else {
      prefix = DateFormat('MMM d').format(dateTime);
    }

    return '$prefix, ${DateFormat('h:mm a').format(dateTime)}';
  }
}
