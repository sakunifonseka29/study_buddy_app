import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_buddy_app/Models/chatModel.dart';
import 'package:study_buddy_app/Models/studygroupModel.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Service/firebaseService.dart';

class ChatService extends FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference for messages
  CollectionReference get messagesCollection =>
      _firestore.collection('messages');

  // Stream of messages for a specific group
  Stream<List<ChatMessage>> getChatMessages(String groupId) {
    return messagesCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    ChatMessage.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  // Send a message to a group
  Future<ChatMessage> sendMessage({
    required String senderId,
    required String senderName,
    String? senderProfileUrl,
    required String groupId,
    required String content,
    String messageType = 'text',
    List<String>? memberIds,
  }) async {
    try {
      final docRef = messagesCollection.doc();

      // Create read status map for all members except sender
      Map<String, bool> readBy = {};
      if (memberIds != null) {
        for (var memberId in memberIds) {
          // If it's the sender, mark as read
          if (memberId == senderId) {
            readBy[memberId] = true;
          } else {
            readBy[memberId] = false;
          }
        }
      }

      final message = ChatMessage(
        messageId: docRef.id,
        senderId: senderId,
        senderName: senderName,
        senderProfileUrl: senderProfileUrl,
        groupId: groupId,
        content: content,
        timestamp: DateTime.now(),
        readBy: readBy,
      );

      await docRef.set(message.toMap());

      // Update the study group with the latest message
      await studyGroupsCollection.doc(groupId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Notify other members
      await _notifyGroupMembers(
        senderId: senderId,
        senderName: senderName,
        groupId: groupId,
        content: content,
      );

      return message;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Notify group members about new messages using the AppNotificationManager
  Future<void> _notifyGroupMembers({
    required String senderId,
    required String senderName,
    required String groupId,
    required String content,
  }) async {
    try {
      // Get the study group
      final groupDoc = await studyGroupsCollection.doc(groupId).get();
      if (!groupDoc.exists) return;

      final group = StudyGroup.fromMap(groupDoc.data() as Map<String, dynamic>);

      // Import the AppNotificationManager using the provider
      // This should be injected in a real implementation
      // For now, we'll use the direct Firestore approach for simplicity

      // Notify all members except the sender
      for (String memberId in group.memberIds) {
        if (memberId != senderId) {
          // Create app notification in Firestore
          await _firestore.collection('notifications').add({
            'userId': memberId,
            'title': 'New message in ${group.groupName}',
            'message':
                '$senderName: ${content.length > 50 ? content.substring(0, 47) + "..." : content}',
            'time': DateTime.now().toIso8601String(),
            'isRead': false,
            'notificationType': 'group_message',
            'payload': {
              'groupId': groupId,
              'senderId': senderId,
              'type': 'group_message',
            },
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to notify group members: $e');
    }
  }

  // Mark messages as read for a user
  Future<void> markMessagesAsRead({
    required String userId,
    required String groupId,
  }) async {
    try {
      // Get unread messages for this user
      final unreadMessages =
          await messagesCollection
              .where('groupId', isEqualTo: groupId)
              .where('readBy.$userId', isEqualTo: false)
              .get();

      // Batch update for performance
      final batch = _firestore.batch();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'readBy.$userId': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId, String groupId) async {
    try {
      final unreadMessages =
          await messagesCollection
              .where('groupId', isEqualTo: groupId)
              .where('readBy.$userId', isEqualTo: false)
              .count()
              .get();

      return unreadMessages.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }

  // Search for users to add to a group
  Future<List<User>> searchUsers(String query, List<String> excludeIds) async {
    try {
      if (query.isEmpty) return [];

      // Search for users where name or email contains the query
      final querySnapshot =
          await usersCollection
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(10)
              .get();

      final results =
          querySnapshot.docs
              .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
              .where((user) => !excludeIds.contains(user.userId))
              .toList();

      // If we have less than 10 results, search by email as well
      if (results.length < 10) {
        final emailQuerySnapshot =
            await usersCollection
                .where('email', isGreaterThanOrEqualTo: query)
                .where('email', isLessThanOrEqualTo: '$query\uf8ff')
                .limit(10 - results.length)
                .get();

        final emailResults =
            emailQuerySnapshot.docs
                .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
                .where(
                  (user) =>
                      !excludeIds.contains(user.userId) &&
                      !results.any((u) => u.userId == user.userId),
                )
                .toList();

        results.addAll(emailResults);
      }

      return results;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
