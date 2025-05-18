import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:study_buddy_app/firebase_options.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  // Stream controller to handle notification responses
  final StreamController<NotificationResponse> selectNotificationStream =
      StreamController<NotificationResponse>.broadcast();

  // Notification channels
  static const String studyReminderChannelId = 'study_reminder_channel';
  static const String taskCompletionChannelId = 'task_completion_channel';
  static const String groupActivityChannelId = 'group_activity_channel';
  static const String scheduleChannelId = 'schedule_channel';

  // Initialize the notification service
  Future<void> initialize() async {
    await _configureLocalTimeZone();
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    _configureSelectNotificationSubject();
  }

  // Background message handler for Firebase Cloud Messaging
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await _initializeLocalNotifications();
    await _showFlutterNotification(message);
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Use default app icon

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification taps
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
  }

  // Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for iOS and web
    if (Platform.isIOS) {
      await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Get FCM token for this device
    final token = await firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // Configure FCM callbacks
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Handle FCM messages received when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );
      _showLocalNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'Study Buddy',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // Handle when user taps on notification to open app
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
    // Navigate based on message data if needed
  }

  // Show FCM notification as local notification
  static Future<void> _showFlutterNotification(RemoteMessage message) async {
    if (message.notification != null) {
      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel_id',
            'Default Channel',
            channelDescription: 'Default notification channel',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // Show a local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel_id',
    String channelName = 'Default Channel',
    String channelDescription = 'Default notification channel',
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Show study reminder notification
  Future<void> showStudyReminderNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      channelId: studyReminderChannelId,
      channelName: 'Study Reminders',
      channelDescription: 'Notifications for study session reminders',
    );
  }

  // Show task completion notification
  Future<void> showTaskCompletionNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      channelId: taskCompletionChannelId,
      channelName: 'Task Completions',
      channelDescription: 'Notifications for task completions and achievements',
    );
  }

  // Show group activity notification
  Future<void> showGroupActivityNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      channelId: groupActivityChannelId,
      channelName: 'Group Activities',
      channelDescription: 'Notifications for study group activities',
    );
  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            scheduleChannelId,
            'Scheduled Reminders',
            channelDescription: 'Notifications for scheduled study sessions',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      if (e.toString().contains('exact_alarms_not_permitted')) {
        // If exact alarms not permitted, throw a more specific exception
        throw Exception(
          'exact_alarms_not_permitted: Please enable exact alarms permission',
        );
      } else {
        // Re-throw any other exceptions
        rethrow;
      }
    }
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Configure time zones for scheduled notifications
  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  // Handle notification selection
  void _configureSelectNotificationSubject() {
    selectNotificationStream.stream.listen((NotificationResponse response) {
      try {
        debugPrint('Notification clicked: ${response.payload}');

        if (response.payload != null) {
          // Parse payload
          final payload = jsonDecode(response.payload!);
          final type = payload['type'];

          // Handle navigation based on notification type
          if (type == 'task_assigned' || type == 'task_due_soon') {
            // Navigate to task details - you'll need a navigation service or other mechanism to handle this
            // e.g., NavigationService.instance.navigateToTaskDetails(payload['taskId']);
          } else if (type == 'study_session') {
            // Navigate to schedule details
            // NavigationService.instance.navigateToScheduleDetails(payload['scheduleId']);
          } else if (type == 'group_message') {
            // Navigate to group chat
            // NavigationService.instance.navigateToGroupChat(payload['groupId']);
          }
        }
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
      }
    });
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      return grantedNotificationPermission ?? false;
    }
    return false;
  }

  // Request exact alarm permissions (for Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          // This method will request the permission and return true if the user granted it
          final bool? hasPermission =
              await androidImplementation.requestExactAlarmsPermission();
          return hasPermission ?? false;
        }
      } catch (e) {
        debugPrint('Error requesting exact alarm permission: $e');
      }
    }

    // For iOS or if Android check fails, we assume permission is granted
    return true;
  } // Check if we can use exact alarms for scheduling notifications

  Future<bool> canUseExactAlarms() async {
    if (Platform.isAndroid) {
      try {
        // First ensure we have basic notification permissions
        final bool granted = await requestPermissions();

        if (!granted) {
          return false;
        }

        // For Android 12+, we need to handle exact alarms separately
        try {
          // Try to schedule a test notification in the far future
          final testId = 999999;
          final testTime = DateTime.now().add(const Duration(days: 1));

          await scheduleNotification(
            id: testId,
            title: 'Permission Test',
            body: 'Testing notifications',
            scheduledDate: testTime,
          );

          // If we get here, permission was granted
          // Now cancel the test notification
          await cancelNotification(testId);
          return true;
        } catch (e) {
          debugPrint('Error testing notification scheduling: $e');

          // If we get an "exact_alarms_not_permitted" error
          if (e.toString().contains('exact_alarms_not_permitted')) {
            return false;
          }

          // For any other error, we'll assume it's not a permission issue
          return true;
        }
      } catch (e) {
        debugPrint('Error checking notification permissions: $e');
        return false;
      }
    }

    // For iOS or if Android check passes
    return true;
  }

  // Open system settings for exact alarms (Android 12+)
  Future<void> openExactAlarmSettings() async {
    if (Platform.isAndroid) {
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          // Try to use the method if available
          try {
            await androidImplementation.requestNotificationsPermission();
          } catch (e) {
            debugPrint('Error opening alarm settings: $e');
            // Fallback to a more general approach
            final Uri uri = Uri.parse(
              'package:android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
            );
            await launchUrl(uri);
          }
        }
      } catch (e) {
        debugPrint('Error opening system settings: $e');
      }
    }
  }

  // Open system settings for alarms and notifications
  Future<void> _openAlarmSettings() async {
    if (Platform.isAndroid) {
      try {
        // Try to use Intent.ACTION_APPLICATION_DETAILS_SETTINGS which is more widely available
        final Uri uri = Uri.parse(
          'package:android.settings.APPLICATION_DETAILS_SETTINGS',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        } else {
          // Fallback to general app settings
          await launchUrl(Uri.parse('package:android.settings.SETTINGS'));
        }
      } catch (e) {
        debugPrint('Error opening settings: $e');
      }
    }
  }

  // Show a permission dialog with explanation
  void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    String buttonText,
    VoidCallback onPressed,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(onPressed: onPressed, child: Text(buttonText)),
            ],
          ),
    );
  }

  // Test if we can use exact alarms and provide a way to fix permissions
  Future<bool> checkAndRequestExactAlarmPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      try {
        // First ensure we have basic notification permissions
        final bool granted = await requestPermissions();

        if (!granted) {
          // Show a dialog explaining why we need notification permissions
          if (context.mounted) {
            _showPermissionDialog(
              context,
              'Notification Permission Required',
              'This app needs notification permission to remind you about your study sessions.',
              'Grant Permission',
              () async {
                await requestPermissions();
                Navigator.pop(context);
              },
            );
          }
          return false;
        }

        // For Android 12+, test if we can use exact alarms
        try {
          // Try to schedule a test notification in the far future
          final testId = 999999;
          final testTime = DateTime.now().add(const Duration(days: 1));

          await scheduleNotification(
            id: testId,
            title: 'Permission Test',
            body: 'Testing notifications',
            scheduledDate: testTime,
          );

          // If we get here, permission was granted
          // Now cancel the test notification
          await cancelNotification(testId);
          return true;
        } catch (e) {
          debugPrint('Error testing notification scheduling: $e');

          // If this is an exact alarms permission error
          if (e.toString().contains('exact_alarms_not_permitted')) {
            if (context.mounted) {
              // Show a dialog explaining the issue and guiding the user
              _showPermissionDialog(
                context,
                'Exact Alarm Permission Required',
                'To set reminder notifications, this app needs permission to schedule exact alarms. Please enable this permission in your device settings.',
                'Open Settings',
                () async {
                  await _openAlarmSettings();
                  Navigator.pop(context);
                },
              );
            }
            return false;
          }

          // For any other error, we'll assume it's not a permission issue
          return true;
        }
      } catch (e) {
        debugPrint('Error checking notification permissions: $e');
        return false;
      }
    }

    // For iOS or if Android check passes
    return true;
  }

  // Clean up resources
  void dispose() {
    selectNotificationStream.close();
  }
}
