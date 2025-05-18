import 'package:study_buddy_app/Models/notificationModel.dart';
import 'package:study_buddy_app/Service/notification_service.dart';
import 'package:study_buddy_app/Service/notificationService.dart'
    as firestore_notifications;
import 'package:study_buddy_app/Service/firebaseService.dart';
import 'dart:convert';

// This service combines both notification systems
class AppNotificationManager extends FirebaseService {
  final NotificationService localNotifications;
  final firestore_notifications.NotificationService firestoreNotifications;

  AppNotificationManager({
    required this.localNotifications,
    required this.firestoreNotifications,
  });

  // Create a notification both in Firestore and as a push notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String notificationType,
    Map<String, dynamic>? payload,
    bool sendPush = true,
  }) async {
    // Create notification in Firestore
    await firestoreNotifications.createNotification(
      userId: userId,
      title: title,
      message: body,
      notificationType: notificationType,
      payload: payload,
    );

    // Also send as push notification if requested
    if (sendPush) {
      final int notificationId = DateTime.now().millisecondsSinceEpoch
          .remainder(100000);

      switch (notificationType) {
        case 'study_reminder':
          await localNotifications.showStudyReminderNotification(
            id: notificationId,
            title: title,
            body: body,
            payload: payload != null ? jsonEncode(payload) : null,
          );
          break;
        case 'task_completion':
          await localNotifications.showTaskCompletionNotification(
            id: notificationId,
            title: title,
            body: body,
            payload: payload != null ? jsonEncode(payload) : null,
          );
          break;
        case 'group_activity':
          await localNotifications.showGroupActivityNotification(
            id: notificationId,
            title: title,
            body: body,
            payload: payload != null ? jsonEncode(payload) : null,
          );
          break;
        default: // Use default notification
          await localNotifications.showStudyReminderNotification(
            id: notificationId,
            title: title,
            body: body,
            payload: payload != null ? jsonEncode(payload) : null,
          );
      }
    }
  }

  // Schedule notification
  Future<void> scheduleNotification({
    required String userId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String notificationType,
    Map<String, dynamic>? payload,
  }) async {
    // Create entry in Firestore (won't be shown until scheduled time)
    await firestoreNotifications.createNotification(
      userId: userId,
      title: title,
      message: body,
      notificationType: notificationType,
      payload: payload,
    );

    // Schedule push notification
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );
    await localNotifications.scheduleNotification(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  // Get all notifications for a user
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    return firestoreNotifications.getUserNotifications(userId);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    return firestoreNotifications.markAsRead(notificationId);
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    return firestoreNotifications.deleteNotification(notificationId);
  }

  // Delete all read notifications for a user
  Future<void> deleteReadNotifications(String userId) async {
    return firestoreNotifications.deleteReadNotifications(userId);
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    return firestoreNotifications.deleteAllNotifications(userId);
  }

  // Create a notification for a new group message
  Future<void> createGroupMessageNotification({
    required String senderId,
    required String senderName,
    required String groupId,
    required String groupName,
    required String content,
    required List<String> memberIds,
  }) async {
    // Don't send notifications to the message sender
    for (String memberId in memberIds) {
      // Skip the sender
      if (memberId == senderId) continue;

      // Create the notification
      await createNotification(
        userId: memberId,
        title: 'New message in $groupName',
        body:
            '$senderName: ${content.length > 50 ? content.substring(0, 47) + "..." : content}',
        notificationType: 'group_message',
        payload: {
          'type': 'group_message',
          'groupId': groupId,
          'senderId': senderId,
          'senderName': senderName,
        },
      );
    }
  }
}
