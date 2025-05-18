import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/Views/notifications_page.dart';

/// A widget that displays a notification badge with an icon
/// Shows a count of unread notifications if any exist
class NotificationBadgeWidget extends ConsumerWidget {
  final bool showIcon;
  final double size;
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    Key? key,
    this.showIcon = true,
    this.size = 24.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(firebaseServiceProvider).currentUserId;

    // If no user is logged in, don't show any badge
    if (userId == null) return const SizedBox();

    // Get notifications
    final notificationsAsyncValue = ref.watch(
      userNotificationsProvider(userId),
    );

    return notificationsAsyncValue.when(
      data: (notifications) {
        // Count unread notifications
        final unreadCount = notifications.where((n) => !n.isRead).length;

        if (unreadCount == 0 && !showIcon) {
          // Don't show anything if there are no unread notifications
          // and we don't want to show the icon
          return const SizedBox();
        }

        return GestureDetector(
          onTap:
              onTap ?? () => NotificationsPage.navigateToNotifications(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bell icon
              if (showIcon)
                Icon(Icons.notifications, size: size, color: Colors.deepPurple),

              // Badge with count
              if (unreadCount > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: EdgeInsets.all(size * 0.2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: size * 0.6,
                      minHeight: size * 0.6,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading:
          () =>
              showIcon
                  ? Icon(
                    Icons.notifications,
                    size: size,
                    color: Colors.deepPurple,
                  )
                  : const SizedBox(),
      error:
          (_, __) =>
              showIcon
                  ? Icon(
                    Icons.notifications,
                    size: size,
                    color: Colors.deepPurple,
                  )
                  : const SizedBox(),
    );
  }
}
