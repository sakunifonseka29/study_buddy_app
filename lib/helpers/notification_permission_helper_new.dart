import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:study_buddy_app/Models/task_schedule.dart';
import 'package:study_buddy_app/Service/notification_service.dart'
    as local_notifications;
import 'package:study_buddy_app/Service/notificationService.dart'
    as firebase_notifications;
import 'package:study_buddy_app/Views/notifications_page.dart';

class NotificationHelper {
  final local_notifications.NotificationService _notificationService =
      local_notifications.NotificationService();
  final firebase_notifications.NotificationService
  _firebaseNotificationService = firebase_notifications.NotificationService();

  // Schedule a notification for a study session
  Future<bool> scheduleReminderForSession({
    required BuildContext context,
    required TaskSchedule schedule,
    required DateTime reminderTime,
    required String reminderText,
    String? userId,
  }) async {
    try {
      // First check if we have the required permissions
      final bool hasPermission = await _notificationService
          .checkAndRequestExactAlarmPermission(context);

      if (!hasPermission) {
        // Permission issues are handled by the checkAndRequestExactAlarmPermission method
        // which shows appropriate dialogs
        return false;
      }

      // Generate a unique ID for the notification
      final int notificationId =
          DateTime.now().millisecondsSinceEpoch % 100000 + schedule.hashCode;

      // Create a more detailed payload that includes schedule information for the notification page
      final Map<String, dynamic> payloadData = {
        "type": "study_session_reminder",
        "subject": schedule.subject,
        "description": schedule.description,
        "time": schedule.time,
        "reminderText": reminderText,
      };

      // Schedule the push notification
      await _notificationService.scheduleNotification(
        id: notificationId,
        title: 'Study Session Reminder',
        body: '${schedule.subject}: ${schedule.description} starting soon',
        scheduledDate: reminderTime,
        payload: jsonEncode(payloadData),
      );

      // Also store in Firestore for the notifications page if we have a userId
      if (userId != null) {
        await _storeNotificationInFirebase(
          userId: userId,
          title: 'Study Session Reminder',
          message: '${schedule.subject}: ${schedule.description} starting soon',
          notificationType: 'study_reminder',
          payload: payloadData,
        );
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set reminder: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Show a notification for the start of a study session
  Future<bool> notifySessionStarted({
    required BuildContext context,
    required TaskSchedule schedule,
    String? userId,
  }) async {
    try {
      // Generate a unique ID for the notification
      final int notificationId =
          DateTime.now().millisecondsSinceEpoch % 100000 + schedule.hashCode;

      // Create a more detailed payload that includes schedule information
      final Map<String, dynamic> payloadData = {
        "type": "study_session_started",
        "subject": schedule.subject,
        "description": schedule.description,
        "time": schedule.time,
      };

      // Show the push notification
      await _notificationService.showStudyReminderNotification(
        id: notificationId,
        title: 'Study Session Started',
        body: 'You are now studying ${schedule.subject}',
        payload: jsonEncode(payloadData),
      );

      // Also store in Firestore for the notifications page if we have a userId
      if (userId != null) {
        await _storeNotificationInFirebase(
          userId: userId,
          title: 'Study Session Started',
          message: 'You are now studying ${schedule.subject}',
          notificationType: 'study_reminder',
          payload: payloadData,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error showing study session notification: $e');
      return false;
    }
  }

  // Show a notification for the completion of a study session
  Future<bool> notifySessionCompleted({
    required BuildContext context,
    required TaskSchedule schedule,
    String? userId,
  }) async {
    try {
      // Generate a unique ID for the notification
      final int notificationId =
          DateTime.now().millisecondsSinceEpoch % 100000 + schedule.hashCode;

      // Create a more detailed payload that includes schedule information
      final Map<String, dynamic> payloadData = {
        "type": "study_session_completed",
        "subject": schedule.subject,
        "description": schedule.description,
        "time": schedule.time,
        "xp": 15, // XP earned for completing this session
      };

      // Show the push notification
      await _notificationService.showTaskCompletionNotification(
        id: notificationId,
        title: 'Study Session Completed',
        body: 'Great job completing your ${schedule.subject} session!',
        payload: jsonEncode(payloadData),
      );

      // Also store in Firestore for the notifications page if we have a userId
      if (userId != null) {
        await _storeNotificationInFirebase(
          userId: userId,
          title: 'Study Session Completed',
          message:
              'Great job completing your ${schedule.subject} session! You earned 15 XP.',
          notificationType: 'task_completion',
          payload: payloadData,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error showing completion notification: $e');
      return false;
    }
  }

  // Store notification in Firebase for the notification page
  Future<void> _storeNotificationInFirebase({
    required String userId,
    required String title,
    required String message,
    required String notificationType,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _firebaseNotificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        notificationType: notificationType,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error storing notification in Firebase: $e');
    }
  }

  // Handle notification navigation
  static void handleNotificationNavigation(
    BuildContext context,
    String? payload,
  ) {
    if (payload == null) return;

    try {
      final data = jsonDecode(payload);
      final String type = data['type'] ?? '';

      switch (type) {
        case 'study_session_reminder':
        case 'study_session_started':
        case 'study_session_completed':
          // Navigate to notification page with the specific notification
          NotificationsPage.navigateToNotifications(context);
          break;

        default:
          debugPrint('Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('Error handling notification navigation: $e');
    }
  }
}
