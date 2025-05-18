import 'package:flutter/material.dart';
import 'package:study_buddy_app/Models/studyscheduleModel.dart';
import 'package:study_buddy_app/Service/firebaseService.dart';
import 'package:study_buddy_app/Service/notificationService.dart';

class ScheduleService extends FirebaseService {
  Future<StudySchedule> createSchedule({
    required String userId,
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    String? taskDescription,
    bool isGroupSession = false,
    String? groupId,
  }) async {
    try {
      final docRef = schedulesCollection.doc();
      final schedule = StudySchedule(
        scheduleId: docRef.id,
        userId: userId,
        subject: subject,
        startTime: startTime,
        endTime: endTime,
        taskDescription: taskDescription,
        isGroupSession: isGroupSession,
        groupId: groupId,
      );

      await docRef.set(schedule.toMap());
      return schedule;
    } catch (e) {
      throw Exception('Failed to create schedule: $e');
    }
  }

  Future<List<StudySchedule>> getUserSchedules(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot =
          await schedulesCollection
              .where('userId', isEqualTo: userId)
              .where('startTime', isGreaterThanOrEqualTo: startDate)
              .where('startTime', isLessThanOrEqualTo: endDate)
              .orderBy('startTime')
              .get();

      return snapshot.docs
          .map(
            (doc) => StudySchedule.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get user schedules: $e');
    }
  }

  Future<void> markScheduleAsCompleted(String scheduleId) async {
    try {
      await schedulesCollection.doc(scheduleId).update({'isCompleted': true});
    } catch (e) {
      throw Exception('Failed to mark schedule as completed: $e');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await schedulesCollection.doc(scheduleId).delete();
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  Future<void> scheduleStudySessionReminders(
    String userId,
    StudySchedule schedule,
  ) async {
    try {
      final notificationService = NotificationService();

      // Schedule notification 15 minutes before study time
      final reminderTime = schedule.startTime.subtract(
        const Duration(minutes: 15),
      );
      if (reminderTime.isAfter(DateTime.now())) {
        await notificationService.scheduleNotification(
          id: schedule.scheduleId.hashCode,
          title: 'Upcoming Study Session',
          body: 'Your ${schedule.subject} study session starts in 15 minutes',
          scheduledDate: reminderTime,
          payload:
              '{"type":"study_session","scheduleId":"${schedule.scheduleId}"}',
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule study reminder: $e');
    }
  }
}
