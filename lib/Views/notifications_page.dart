// notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:study_buddy_app/Models/notificationModel.dart';
import 'package:study_buddy_app/providerService.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  // Static method for navigating to the notifications page
  static void navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  DateRange _currentFilter = DateRange.all;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(firebaseServiceProvider).currentUserId;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('You need to be logged in to view notifications'),
        ),
      );
    }

    final notificationsAsyncValue = ref.watch(
      userNotificationsProvider(userId),
    );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showDeleteOptions(context, ref, userId),
              tooltip: 'Delete notifications',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Study Reminders'),
              Tab(text: 'Tasks'),
              Tab(text: 'Group'),
            ],
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
          ),
        ),
        body: notificationsAsyncValue.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(child: Text('No notifications yet'));
            }

            // Filter notifications by date
            final filteredNotifications =
                notifications
                    .where((n) => _currentFilter.isInRange(n.time))
                    .toList();

            // Group notifications by type
            final allNotifications = filteredNotifications;
            final studyReminders =
                filteredNotifications
                    .where((n) => n.notificationType == 'study_reminder')
                    .toList();
            final taskNotifications =
                filteredNotifications
                    .where((n) => n.notificationType == 'task_completion')
                    .toList();
            final groupNotifications =
                filteredNotifications
                    .where(
                      (n) =>
                          n.notificationType == 'group_activity' ||
                          n.notificationType == 'group_message',
                    )
                    .toList();

            return Column(
              children: [
                NotificationDateFilter(
                  currentFilter: _currentFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _currentFilter = filter;
                    });
                  },
                ),
                NotificationStatsWidget(notifications: filteredNotifications),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildNotificationList(context, ref, allNotifications),
                      studyReminders.isEmpty
                          ? const Center(child: Text('No study reminders'))
                          : _buildNotificationList(
                            context,
                            ref,
                            studyReminders,
                          ),
                      taskNotifications.isEmpty
                          ? const Center(child: Text('No task notifications'))
                          : _buildNotificationList(
                            context,
                            ref,
                            taskNotifications,
                          ),
                      groupNotifications.isEmpty
                          ? const Center(child: Text('No group notifications'))
                          : _buildNotificationList(
                            context,
                            ref,
                            groupNotifications,
                          ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (err, stack) => Center(
                child: Text('Error loading notifications: ${err.toString()}'),
              ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> notifications,
  ) {
    return Column(
      children: [
        // Information header card
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.deepPurple.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Swipe left to delete',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tap to mark as read and navigate',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Notification list
        Expanded(
          child:
              notifications.isEmpty
                  ? const Center(
                    child: Text('No notifications in this category'),
                  )
                  : RefreshIndicator(
                    onRefresh: () async {
                      // Refresh the notifications
                      final _ = ref.refresh(
                        userNotificationsProvider(
                          ref.read(firebaseServiceProvider).currentUserId!,
                        ),
                      );
                    },
                    color: Colors.deepPurple,
                    child: AnimatedList(
                      initialItemCount: notifications.length,
                      itemBuilder: (context, index, animation) {
                        final notification = notifications[index];
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: NotificationItem(
                              notification: notification,
                              onTap:
                                  () => _handleNotificationTap(
                                    context,
                                    ref,
                                    notification,
                                  ),
                              onDismiss:
                                  () => _deleteNotification(
                                    context,
                                    ref,
                                    notification,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }

  void _showDeleteOptions(BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete read notifications'),
                onTap: () {
                  _deleteReadNotifications(context, ref, userId);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Delete all notifications'),
                onTap: () {
                  _deleteAllNotifications(context, ref, userId);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    // Mark as read
    if (!notification.isRead) {
      await ref
          .read(appNotificationManagerProvider)
          .markAsRead(notification.notificationId);
      // Refresh notifications list
      final _ = ref.refresh(userNotificationsProvider(notification.userId));
    }

    // Handle navigation based on notification type
    if (notification.payload != null) {
      final payload = notification.payload!;

      switch (notification.notificationType) {
        case 'task_completion':
          if (payload.containsKey('taskId')) {
            // Navigate to task detail page
            // Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailPage(taskId: payload['taskId'])));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigating to task ${payload['taskId']}'),
              ),
            );
          }
          break;
        case 'group_activity':
          if (payload.containsKey('groupId')) {
            // Navigate to group page
            // Navigator.push(context, MaterialPageRoute(builder: (context) => GroupDetailPage(groupId: payload['groupId'])));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigating to group ${payload['groupId']}'),
              ),
            );
          }
          break;
        case 'study_reminder':
          // Navigate to schedule or relevant section
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening study schedule')),
          );
          break;
      }
    }
  }

  Future<void> _deleteNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    try {
      await ref
          .read(firestoreNotificationServiceProvider)
          .deleteNotification(notification.notificationId);

      // Refresh notifications list
      final _ = ref.refresh(userNotificationsProvider(notification.userId));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Future<void> _deleteReadNotifications(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      await ref
          .read(firestoreNotificationServiceProvider)
          .deleteReadNotifications(userId);

      // Refresh notifications list
      final _ = ref.refresh(userNotificationsProvider(userId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Read notifications deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Future<void> _deleteAllNotifications(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      await ref
          .read(firestoreNotificationServiceProvider)
          .deleteAllNotifications(userId);

      // Refresh notifications list
      final _ = ref.refresh(userNotificationsProvider(userId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }
}

class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Format the time
    final dateFormat = DateFormat('MMM d, h:mm a');
    final formattedTime = dateFormat.format(notification.time);

    // Determine the notification icon based on type
    IconData notificationIcon;
    Color iconColor;

    switch (notification.notificationType) {
      case 'study_reminder':
        notificationIcon = Icons.book;
        iconColor = Colors.blue;
        break;
      case 'task_completion':
        notificationIcon = Icons.task_alt;
        iconColor = Colors.green;
        break;
      case 'group_activity':
        notificationIcon = Icons.group;
        iconColor = Colors.orange;
        break;
      default:
        notificationIcon = Icons.notifications;
        iconColor = Colors.purple;
    }

    return Dismissible(
      key: Key(notification.notificationId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color:
            notification.isRead
                ? null
                : theme.colorScheme.primaryContainer.withOpacity(0.3),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(notificationIcon, color: iconColor),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 4),
              Text(formattedTime, style: theme.textTheme.bodySmall),
            ],
          ),
          trailing:
              notification.isRead
                  ? null
                  : Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class NotificationStatsWidget extends StatelessWidget {
  final List<AppNotification> notifications;

  const NotificationStatsWidget({Key? key, required this.notifications})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int total = notifications.length;
    final int unread = notifications.where((n) => !n.isRead).length;
    final int studyReminders =
        notifications
            .where((n) => n.notificationType == 'study_reminder')
            .length;
    final int taskNotifications =
        notifications
            .where((n) => n.notificationType == 'task_completion')
            .length;
    final int groupNotifications =
        notifications
            .where(
              (n) =>
                  n.notificationType == 'group_activity' ||
                  n.notificationType == 'group_message',
            )
            .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                total,
                'Total',
                Icons.notifications,
                Colors.deepPurple,
              ),
              _buildStatItem(
                context,
                unread,
                'Unread',
                Icons.mark_email_unread,
                Colors.red,
              ),
              _buildStatItem(
                context,
                studyReminders,
                'Study',
                Icons.book,
                Colors.blue,
              ),
              _buildStatItem(
                context,
                taskNotifications,
                'Tasks',
                Icons.task_alt,
                Colors.green,
              ),
              _buildStatItem(
                context,
                groupNotifications,
                'Group',
                Icons.group,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    int count,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class NotificationDateFilter extends StatefulWidget {
  final Function(DateRange) onFilterChanged;
  final DateRange currentFilter;

  const NotificationDateFilter({
    Key? key,
    required this.onFilterChanged,
    required this.currentFilter,
  }) : super(key: key);

  @override
  State<NotificationDateFilter> createState() => _NotificationDateFilterState();
}

class _NotificationDateFilterState extends State<NotificationDateFilter> {
  late DateRange _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              DateRange.values.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter.displayText),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple.withOpacity(0.2),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        widget.onFilterChanged(filter);
                      }
                    },
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

enum DateRange { all, today, yesterday, lastWeek, lastMonth }

extension DateRangeExtension on DateRange {
  String get displayText {
    switch (this) {
      case DateRange.all:
        return 'All';
      case DateRange.today:
        return 'Today';
      case DateRange.yesterday:
        return 'Yesterday';
      case DateRange.lastWeek:
        return 'Last 7 days';
      case DateRange.lastMonth:
        return 'Last 30 days';
    }
  }

  bool isInRange(DateTime date) {
    final now = DateTime.now();
    switch (this) {
      case DateRange.all:
        return true;
      case DateRange.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case DateRange.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;
      case DateRange.lastWeek:
        final lastWeek = now.subtract(const Duration(days: 7));
        return date.isAfter(lastWeek) || date.isAtSameMomentAs(lastWeek);
      case DateRange.lastMonth:
        final lastMonth = now.subtract(const Duration(days: 30));
        return date.isAfter(lastMonth) || date.isAtSameMomentAs(lastMonth);
    }
  }
}
