import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/Views/dashbord.dart';
import 'package:study_buddy_app/Views/login_page.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/Service/app_initialization_service.dart';
import 'package:study_buddy_app/Service/notification_service.dart';
import 'package:study_buddy_app/Service/app_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Create a provider for the notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set up the background message handler for Firebase Cloud Messaging
  FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler,
  );

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    // Use AndroidProvider.debug for development
    androidProvider: AndroidProvider.debug,
    // Use AppleProvider.appAttest for iOS/macOS
    appleProvider: AppleProvider.deviceCheck,
  );
  // Initialize the notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize app services including monthly points reset check
  final appInitService = AppInitializationService();
  await appInitService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Access notification service if needed in the widget
    final notificationService = ref.watch(notificationServiceProvider);

    return MaterialApp(
      title: 'Study Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (user) => user != null ? const Dashboard() : const LoginPage(),
        loading:
            () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
        error: (_, __) => const LoginPage(),
      ),
    );
  }
}
