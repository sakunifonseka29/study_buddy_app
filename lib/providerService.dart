import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/Service/firebaseservice.dart';
import 'package:study_buddy_app/Service/studygroupService.dart';
import 'package:study_buddy_app/Service/userservice.dart';
import 'package:study_buddy_app/Service/scheduleService.dart';
import 'package:study_buddy_app/Service/rewardService.dart'; // Fixed typo from 'rewordService.dart'
import 'package:study_buddy_app/Service/resourceService.dart';
import 'package:study_buddy_app/Service/notification_service.dart'
    as local_notifications;
import 'package:study_buddy_app/Service/notificationService.dart'
    as firestore_notifications;
import 'package:study_buddy_app/Service/app_notification_service.dart';
import 'package:study_buddy_app/Service/matchingService.dart';
import 'package:study_buddy_app/Service/taskService.dart';
import 'package:study_buddy_app/Service/chatService.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Models/studygroupModel.dart';
import 'package:study_buddy_app/Models/task_model.dart';
import 'package:study_buddy_app/Models/notificationModel.dart';
import 'package:study_buddy_app/Service/authService.dart';
import 'package:study_buddy_app/Models/task_schedule.dart';

// Firebase Services Providers
final firebaseServiceProvider = Provider<FirebaseService>(
  (ref) => FirebaseService(),
);

final userServiceProvider = Provider<UserService>((ref) => UserService());

final studyGroupServiceProvider = Provider<StudyGroupService>(
  (ref) => StudyGroupService(),
);

final scheduleServiceProvider = Provider<ScheduleService>(
  (ref) => ScheduleService(),
);

final rewardServiceProvider = Provider<RewardService>((ref) => RewardService());

final resourceServiceProvider = Provider<ResourceService>(
  (ref) => ResourceService(),
);

final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

// Schedule provider
final taskScheduleProvider = StateNotifierProvider<
  TaskScheduleNotifier,
  Map<DateTime, List<TaskSchedule>>
>((ref) => TaskScheduleNotifier());

// Task providers
final userTasksProvider = FutureProvider<List<Task>>((ref) async {
  final userId = ref.watch(firebaseServiceProvider).currentUserId;
  if (userId == null) {
    return [];
  }
  return ref.watch(taskServiceProvider).getUserTasks(userId);
});

final userOngoingTasksProvider = FutureProvider<List<Task>>((ref) async {
  final userId = ref.watch(firebaseServiceProvider).currentUserId;
  if (userId == null) {
    return [];
  }
  return ref.watch(taskServiceProvider).getUserOngoingTasks(userId);
});

// Provider for suggested tasks based on subject
final suggestedTasksProvider = FutureProvider.family<List<Task>, String>((
  ref,
  subject,
) async {
  final userId = ref.watch(firebaseServiceProvider).currentUserId;
  if (userId == null) {
    return [];
  }

  // Use the subject provided, or default to "Mathematics" if empty
  final subjectToUse = subject.isEmpty ? "Mathematics" : subject;
  return ref.watch(taskServiceProvider).getSuggestedTasks(userId, subjectToUse);
});

// Selected subject provider for suggested tasks
final selectedSubjectProvider = StateProvider<String>((ref) => '');

// Provider for local notifications (push notifications)
final localNotificationServiceProvider =
    Provider<local_notifications.NotificationService>(
      (ref) => local_notifications.NotificationService(),
    );

// Provider for firestore notifications (database notifications)
final firestoreNotificationServiceProvider =
    Provider<firestore_notifications.NotificationService>(
      (ref) => firestore_notifications.NotificationService(),
    );

// Combined notification manager for both systems
final appNotificationManagerProvider = Provider<AppNotificationManager>((ref) {
  final localService = ref.watch(localNotificationServiceProvider);
  final firestoreService = ref.watch(firestoreNotificationServiceProvider);
  return AppNotificationManager(
    localNotifications: localService,
    firestoreNotifications: firestoreService,
  );
});

// Provider for user notifications
final userNotificationsProvider =
    FutureProvider.family<List<AppNotification>, String>((ref, userId) async {
      final notificationManager = ref.watch(appNotificationManagerProvider);
      return notificationManager.getUserNotifications(userId);
    });

final matchingServiceProvider = Provider<MatchingService>(
  (ref) => MatchingService(),
);

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth State Provider
final authStateProvider = StreamProvider<auth.User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

// Current User Data Provider
// We use family and autoDispose to ensure data is tied to the current userId and cache is cleared when no longer needed
final currentUserDataProvider = FutureProvider.autoDispose<User?>((ref) async {
  // Watch userId changes to automatically refresh when user changes
  final userId = ref.watch(firebaseServiceProvider).currentUserId;
  if (userId == null) return null;

  // Add a cache invalidation listener that triggers on auth state changes
  ref.listen(authStateProvider, (previous, next) {
    if (previous != next) {
      ref.invalidateSelf();
    }
  });

  return await ref.read(userServiceProvider).getUser(userId);
});

// Weekly Points Provider
final weeklyPointsProvider = FutureProvider<Map<int, int>>((ref) async {
  final userId = ref.watch(firebaseServiceProvider).currentUserId;
  if (userId == null) {
    // Return empty map with all days set to 0 if not logged in
    return {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
  }
  return await ref.read(rewardServiceProvider).getUserPointsLastWeek(userId);
});

// User Study Groups Provider
final userStudyGroupsProvider = FutureProvider<List<StudyGroup>>((ref) async {
  final userId = ref.watch(firebaseServiceProvider).currentUserId;
  if (userId == null) return [];
  return await ref.read(studyGroupServiceProvider).getUserStudyGroups(userId);
});

// Leaderboard Provider
final leaderboardProvider = FutureProvider<List<User>>((ref) async {
  return await ref.read(rewardServiceProvider).getLeaderboard();
});

// Add your providers here

// Schedule notifier class to manage state
class TaskScheduleNotifier
    extends StateNotifier<Map<DateTime, List<TaskSchedule>>> {
  TaskScheduleNotifier() : super(_initializeEvents()) {
    // Load schedules when the notifier is created
    fetchSchedulesFromFirebase();
  }

  static Map<DateTime, List<TaskSchedule>> _initializeEvents() {
    // Initialize with empty map - schedules will be loaded from Firebase/backend
    final Map<DateTime, List<TaskSchedule>> events = {};
    return events;
  }

  // New method to fetch schedules from Firebase
  Future<void> fetchSchedulesFromFirebase() async {
    try {
      final FirebaseService firebaseService = FirebaseService();
      final String? userId = firebaseService.currentUserId;

      if (userId == null) {
        // Not logged in, keep the state empty
        return;
      }

      // Get schedules from Firebase
      final schedulesCollection = firebaseService.schedulesCollection;
      final snapshot =
          await schedulesCollection.where('userId', isEqualTo: userId).get();

      final Map<DateTime, List<TaskSchedule>> newState = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        try {
          // Parse start time
          DateTime startTime;
          if (data.containsKey('startTime')) {
            if (data['startTime'] is String) {
              startTime = DateTime.parse(data['startTime'] as String);
            } else {
              // Assuming it's a Timestamp
              startTime = (data['startTime'] as dynamic).toDate();
            }
          } else {
            // Skip this entry if no startTime
            continue;
          }

          // Parse end time
          DateTime endTime;
          if (data.containsKey('endTime')) {
            if (data['endTime'] is String) {
              endTime = DateTime.parse(data['endTime'] as String);
            } else {
              // Assuming it's a Timestamp
              endTime = (data['endTime'] as dynamic).toDate();
            }
          } else {
            // Default to 1 hour after start if no endTime
            endTime = startTime.add(const Duration(hours: 1));
          }

          // Normalize the date to remove time
          final DateTime normalizedDate = DateTime(
            startTime.year,
            startTime.month,
            startTime.day,
          );

          // Create a TaskSchedule object
          final schedule = TaskSchedule(
            subject: data['subject'] as String? ?? 'Study',
            description: data['taskDescription'] as String? ?? 'Study session',
            time: _formatTimeRange(startTime, endTime),
            isGroup: data['isGroupSession'] as bool? ?? false,
            location: data['location'] as String?,
            notes: data['notes'] as String?,
          );

          // Add to the map
          if (newState.containsKey(normalizedDate)) {
            newState[normalizedDate]!.add(schedule);
          } else {
            newState[normalizedDate] = [schedule];
          }
        } catch (e) {
          print('Error processing schedule: $e');
          continue;
        }
      }

      // Update the state
      state = newState;
    } catch (e) {
      print('Error fetching schedules: $e');
    }
  }

  // Helper method to format time range
  static String _formatTimeRange(DateTime start, DateTime end) {
    final startFormat = _formatTime(start);
    final endFormat = _formatTime(end);
    return '$startFormat - $endFormat';
  }

  // Helper method to format time
  static String _formatTime(DateTime dateTime) {
    final hour =
        dateTime.hour > 12
            ? dateTime.hour - 12
            : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Get events for a specific day
  List<TaskSchedule> getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return state[normalizedDay] ?? [];
  }

  // Get today's events
  List<TaskSchedule> getTodayEvents() {
    final today = DateTime.now();
    final normalizedDay = DateTime(today.year, today.month, today.day);
    return state[normalizedDay] ?? [];
  }

  // Get events for the current week
  Map<DateTime, List<TaskSchedule>> getCurrentWeekEvents() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final Map<DateTime, List<TaskSchedule>> weekEvents = {};

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final normalizedDay = DateTime(day.year, day.month, day.day);

      if (state.containsKey(normalizedDay)) {
        weekEvents[normalizedDay] = state[normalizedDay]!;
      }
    }

    return weekEvents;
  }

  // Add a new event
  void addEvent(DateTime day, TaskSchedule schedule) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final existingEvents = state[normalizedDay] ?? [];

    // Create a new Map with the updated events
    final Map<DateTime, List<TaskSchedule>> updatedState = Map.from(state);
    updatedState[normalizedDay] = [...existingEvents, schedule];

    state = updatedState;
  }

  // Delete an event
  void deleteEvent(DateTime day, TaskSchedule scheduleToDelete) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final existingEvents = state[normalizedDay] ?? [];

    if (existingEvents.isEmpty) return;

    // Create a new list without the schedule to delete
    final updatedEvents =
        existingEvents
            .where(
              (schedule) =>
                  !(schedule.subject == scheduleToDelete.subject &&
                      schedule.description == scheduleToDelete.description &&
                      schedule.time == scheduleToDelete.time),
            )
            .toList();

    // Create a new Map with the updated events
    final Map<DateTime, List<TaskSchedule>> updatedState = Map.from(state);

    if (updatedEvents.isEmpty) {
      updatedState.remove(normalizedDay);
    } else {
      updatedState[normalizedDay] = updatedEvents;
    }

    state = updatedState;
  }

  // Edit an event
  void editEvent(
    DateTime day,
    TaskSchedule oldSchedule,
    TaskSchedule newSchedule,
  ) {
    // First delete the old schedule
    deleteEvent(day, oldSchedule);

    // Then add the new one
    addEvent(day, newSchedule);
  }

  // Get subject color map
  static Map<String, int> getSubjectColorMap() {
    return {
      'mathematics': 0xFF2196F3, // blue
      'biology': 0xFF4CAF50, // green
      'chemistry': 0xFFFF9800, // orange
      'physics': 0xFFF44336, // red
      'computer science': 0xFF9C27B0, // purple
      'history': 0xFF795548, // brown
      'literature': 0xFF009688, // teal
      'english': 0xFF3F51B5, // indigo
      'art': 0xFFE91E63, // pink
      'music': 0xFF673AB7, // deep purple
      'physical education': 0xFF4CAF50, // green
    };
  }
}
