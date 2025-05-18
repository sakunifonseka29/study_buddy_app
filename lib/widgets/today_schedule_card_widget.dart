import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/Views/schedule_page.dart';
import 'package:study_buddy_app/widgets/schedule_list_widget.dart';

class TodayScheduleCardWidget extends ConsumerWidget {
  const TodayScheduleCardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () {
          // Navigate to the schedule page when the card is tapped
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const SchedulePage()));
        },
        borderRadius: BorderRadius.circular(15),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            height: 320, // Fixed height to show about 3 tasks
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with View All button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // Add button
                        IconButton(
                          onPressed: () {
                            // Navigate to the schedule page
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SchedulePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.deepPurple),
                          tooltip: 'Add Session',
                        ),
                        // View all button
                        TextButton.icon(
                          onPressed: () {
                            // Navigate to the schedule page when the View All button is tapped
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SchedulePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('View All'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Divider with gradient
                Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple,
                        Colors.deepPurple.shade300,
                        Colors.deepPurple.shade100,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Schedule list
                const Expanded(child: ScheduleListWidget()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
