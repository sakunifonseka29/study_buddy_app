import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/Views/notifications_page.dart';
import 'package:study_buddy_app/widgets/notification_badge_widget.dart';
import 'package:study_buddy_app/Models/notificationModel.dart';

class NotificationCardWidget extends ConsumerWidget {
  const NotificationCardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(firebaseServiceProvider).currentUserId;

    // If no user is logged in, don't show this widget
    if (userId == null) return const SizedBox();

    // Get notifications
    final notificationsAsyncValue = ref.watch(
      userNotificationsProvider(userId),
    );

    return notificationsAsyncValue.when(
      data: (notifications) {
        // Count unread notifications
        final unreadCount = notifications.where((n) => !n.isRead).length;

        if (unreadCount == 0) {
          // Show a minimal card if there are no unread notifications
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(
                  Icons.notifications_none,
                  color: Colors.grey,
                ),
                title: const Text("You're all caught up!"),
                subtitle: const Text("No new notifications"),
                trailing: TextButton(
                  onPressed:
                      () => NotificationsPage.navigateToNotifications(context),
                  child: const Text("VIEW ALL"),
                ),
              ),
            ),
          );
        }

        // Show a more prominent card if there are unread notifications
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NotificationBadgeWidget(size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "You have $unreadCount unread notification${unreadCount > 1 ? 's' : ''}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Show a preview of the most recent notification
                  if (notifications.isNotEmpty)
                    Text(
                      _getRecentNotificationPreview(notifications),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed:
                          () => NotificationsPage.navigateToNotifications(
                            context,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("VIEW ALL"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  String _getRecentNotificationPreview(List<AppNotification> notifications) {
    // Sort by date descending
    final sortedNotifications = [...notifications];
    sortedNotifications.sort((a, b) => b.time.compareTo(a.time));

    // Get the most recent unread notification
    final unreadNotifications =
        sortedNotifications.where((n) => !n.isRead).toList();
    if (unreadNotifications.isNotEmpty) {
      final latest = unreadNotifications.first;
      return latest.title;
    } else if (sortedNotifications.isNotEmpty) {
      return sortedNotifications.first.title;
    }

    return "No recent notifications";
  }
}
