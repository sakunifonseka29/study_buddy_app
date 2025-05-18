import 'package:study_buddy_app/Models/notificationModel.dart';
import 'package:study_buddy_app/Service/firebaseservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService extends FirebaseService {
  Future<AppNotification> createNotification({
    required String userId,
    required String title,
    required String message,
    required String notificationType,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final docRef = notificationsCollection.doc();
      final notification = AppNotification(
        notificationId: docRef.id,
        userId: userId,
        title: title,
        message: message,
        time: DateTime.now(),
        notificationType: notificationType,
        payload: payload,
      );

      await docRef.set(notification.toMap());
      return notification;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      final snapshot =
          await notificationsCollection
              .where('userId', isEqualTo: userId)
              .orderBy('time', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                AppNotification.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  showStudyReminderNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) {}

  scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) {}

  // Delete a specific notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  } // Delete all read notifications for a user

  Future<void> deleteReadNotifications(String userId) async {
    try {
      final snapshot =
          await notificationsCollection
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: true)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete read notifications: $e');
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot =
          await notificationsCollection
              .where('userId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }
}
