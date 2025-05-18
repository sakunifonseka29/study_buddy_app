import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/Views/notifications_page.dart';

class GreetingWidget extends ConsumerWidget {
  const GreetingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use watchAsyncValue to get access to the full AsyncValue object
    // and select() to help with proper rebuilding
    final userData = ref.watch(currentUserDataProvider.select((data) => data));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userData.when(
                data:
                    (user) => Text(
                      'Hello, ${user?.name ?? 'Student'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                loading:
                    () => const Text(
                      'Hello!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                error:
                    (_, __) => const Text(
                      'Hello!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
              const Text(
                'Stay focused and keep learning!',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Colors.deepPurple,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
