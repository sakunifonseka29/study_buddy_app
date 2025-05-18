import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String messageId;
  final String senderId;
  final String senderName;
  final String? senderProfileUrl;
  final String groupId;
  final String content;
  final DateTime timestamp;
  final Map<String, bool>? readBy; // User IDs mapped to read status

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    this.senderProfileUrl,
    required this.groupId,
    required this.content,
    required this.timestamp,
    this.readBy,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['messageId'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      senderProfileUrl: map['senderProfileUrl'],
      groupId: map['groupId'],
      content: map['content'],
      timestamp:
          (map['timestamp'] is Timestamp)
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.parse(map['timestamp']),
      readBy:
          map['readBy'] != null ? Map<String, bool>.from(map['readBy']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileUrl': senderProfileUrl,
      'groupId': groupId,
      'content': content,
      'timestamp': timestamp,
      'readBy': readBy,
    };
  }
}
