import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/Models/task_schedule.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/Views/schedule_page.dart';
import 'package:intl/intl.dart';

class ScheduleListWidget extends ConsumerWidget {
  const ScheduleListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(firebaseServiceProvider).currentUserId;
    final scheduleNotifier = ref.watch(taskScheduleProvider.notifier);

    if (userId == null) {
      return const Center(child: Text('Please login to view your schedule'));
    }

    // Get today's schedule from the provider
    final schedules = scheduleNotifier.getTodayEvents();
    if (schedules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tasks scheduled for today',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Sort schedules by time
    schedules.sort((a, b) {
      // Extract time for comparison
      final aTime = a.time.split(' - ').first.trim();
      final bTime = b.time.split(' - ').first.trim();

      // Simple string comparison will work for standard time formats
      return aTime.compareTo(bTime);
    });

    return ListView.separated(
      itemCount: schedules.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return ScheduleItemWidget(
          schedule: schedule,
          onTap: () {
            // Navigate to schedule page when tapped
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SchedulePage()),
            );
          },
        );
      },
    );
  }
}

class ScheduleItemWidget extends StatelessWidget {
  final TaskSchedule schedule;
  final VoidCallback? onTap;

  const ScheduleItemWidget({super.key, required this.schedule, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Get color based on subject
    final Color subjectColor = _getSubjectColor(schedule.subject);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: subjectColor.withOpacity(0.2),
                  child: Icon(
                    schedule.isGroup ? Icons.group : Icons.book,
                    color: subjectColor,
                  ),
                ),
                if (schedule.isGroup)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                // Subject pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    schedule.subject,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: subjectColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Time pill
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      schedule.time,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                schedule.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withOpacity(0.1),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.deepPurple,
                ),
                onPressed: onTap,
                tooltip: 'View details',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Colors.blue;
      case 'biology':
        return Colors.green;
      case 'chemistry':
        return Colors.orange;
      case 'physics':
        return Colors.red;
      case 'computer science':
        return Colors.purple;
      case 'history':
        return Colors.brown;
      case 'literature':
        return Colors.teal;
      case 'english':
        return Colors.indigo;
      case 'art':
        return Colors.pink;
      case 'music':
        return Colors.deepPurple;
      default:
        return Colors.deepPurple;
    }
  }
}
