import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/Views/notifications_page.dart';
import 'package:study_buddy_app/widgets/notification_badge_widget.dart';

class TopBarWidget extends ConsumerWidget {
  const TopBarWidget({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use watchAsyncValue to get access to the full AsyncValue object
    // This provides better handling of loading/error states
    final userData = ref.watch(currentUserDataProvider.select((data) => data));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Study Buddy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          Row(
            children: [
              // Notification Bell with Badge using our reusable widget
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0)),
              const SizedBox(width: 8),
              // User avatar
              CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: userData.when(
                  data: (user) {
                    if (user?.profileImageUrl != null) {
                      return ClipOval(
                        child: Image.network(
                          user!.profileImageUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return const Icon(Icons.person, color: Colors.deepPurple);
                  },
                  loading: () => const CircularProgressIndicator(),
                  error:
                      (_, __) =>
                          const Icon(Icons.person, color: Colors.deepPurple),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
