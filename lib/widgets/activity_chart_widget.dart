import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/providerService.dart';

class ActivityChartWidget extends ConsumerWidget {
  const ActivityChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyPointsAsync = ref.watch(weeklyPointsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title section
          const Text(
            "Activity",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          // Chart Title and Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Weekly points earned",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              weeklyPointsAsync.when(
                data: (pointsData) {
                  // Calculate total points for the week
                  final totalPoints = pointsData.values.fold(
                    0,
                    (sum, points) => sum + points,
                  );

                  // Determine if points are trending up or down compared to average
                  final now = DateTime.now();
                  final currentDay = now.weekday - 1; // 0 = Monday, 6 = Sunday
                  final daysElapsed = currentDay + 1;

                  if (daysElapsed == 0)
                    return const SizedBox(); // First day of week

                  final averagePerDay = totalPoints / daysElapsed;
                  final lastDay =
                      currentDay > 0 ? pointsData[currentDay] ?? 0 : 0;

                  final isUp = lastDay > averagePerDay;

                  return Row(
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isUp ? Colors.green : Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$totalPoints points",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  );
                },
                loading:
                    () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                error:
                    (_, __) => const Text(
                      "Error loading",
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16), // Custom Bar Chart
          SizedBox(
            height: 220, // Slightly reduced height to avoid overflow
            width: double.infinity,
            child: Column(
              children: [
                // Chart Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Y-Axis
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            "100",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            "75",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            "50",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            "25",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),

                      const SizedBox(width: 8),

                      // Bars
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: weeklyPointsAsync.when(
                            data:
                                (pointsData) =>
                                    BarChartContent(pointsData: pointsData),
                            loading:
                                () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            error:
                                (_, __) => const Center(
                                  child: Text(
                                    'Failed to load points data',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Color Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Points earned",
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BarChartContent extends StatelessWidget {
  final Map<int, int> pointsData;

  const BarChartContent({super.key, required this.pointsData});

  @override
  Widget build(BuildContext context) {
    // Get today's weekday (0 = Monday, 6 = Sunday)
    final today = DateTime.now().weekday - 1;

    // Find max points to normalize heights
    final maxPoints = pointsData.values.fold(
      0,
      (max, points) => points > max ? points : max,
    );
    final safeMaxPoints =
        maxPoints > 0 ? maxPoints : 100; // Default to 100 if no points

    // Create data for the bar chart
    final List<BarData> barData = [
      BarData(
        "M",
        _normalizeHeight(pointsData[0] ?? 0, safeMaxPoints),
        today == 0,
        today == 0 ? "${pointsData[0] ?? 0} pts" : null,
      ),
      BarData(
        "T",
        _normalizeHeight(pointsData[1] ?? 0, safeMaxPoints),
        today == 1,
        today == 1 ? "${pointsData[1] ?? 0} pts" : null,
      ),
      BarData(
        "W",
        _normalizeHeight(pointsData[2] ?? 0, safeMaxPoints),
        today == 2,
        today == 2 ? "${pointsData[2] ?? 0} pts" : null,
      ),
      BarData(
        "T",
        _normalizeHeight(pointsData[3] ?? 0, safeMaxPoints),
        today == 3,
        today == 3 ? "${pointsData[3] ?? 0} pts" : null,
      ),
      BarData(
        "F",
        _normalizeHeight(pointsData[4] ?? 0, safeMaxPoints),
        today == 4,
        today == 4 ? "${pointsData[4] ?? 0} pts" : null,
      ),
      BarData(
        "S",
        _normalizeHeight(pointsData[5] ?? 0, safeMaxPoints),
        today == 5,
        today == 5 ? "${pointsData[5] ?? 0} pts" : null,
      ),
      BarData(
        "S",
        _normalizeHeight(pointsData[6] ?? 0, safeMaxPoints),
        today == 6,
        today == 6 ? "${pointsData[6] ?? 0} pts" : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children:
              barData.map((data) => _buildBarItem(context, data)).toList(),
        );
      },
    );
  }

  // Convert raw point value to a height percentage (0.0 to 1.0)
  double _normalizeHeight(int points, int maxPoints) {
    if (maxPoints <= 0) return 0.0;
    return points / maxPoints;
  }

  Widget _buildBarItem(BuildContext context, BarData data) {
    return SizedBox(
      width: 30, // Fixed width for each bar item container
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (data.highlight && data.annotation != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data.annotation!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          if (data.highlight && data.annotation != null)
            Container(
              width: 1,
              height: 5,
              color: Colors.deepPurple.withOpacity(0.3),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate maximum height based on available space
              double maxHeight =
                  constraints.maxHeight -
                  30; // Reserve space for text and padding

              // Ensure we have a non-zero, finite height
              if (maxHeight <= 0 || !maxHeight.isFinite) {
                maxHeight = 100; // Fallback to a reasonable default
              }

              // Ensure data.height is properly bounded (0.0 to 1.0)
              final normalizedHeight = data.height.clamp(0.0, 1.0);

              return Container(
                width: 20,
                height: maxHeight * normalizedHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      data.highlight
                          ? Colors.deepPurple
                          : Colors.deepPurple.withOpacity(0.7),
                      data.highlight
                          ? Colors.deepPurple.withOpacity(0.7)
                          : Colors.deepPurple.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: data.highlight ? FontWeight.bold : FontWeight.normal,
              color: data.highlight ? Colors.deepPurple : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class BarData {
  final String label;
  final double height;
  final bool highlight;
  final String? annotation;

  BarData(this.label, this.height, this.highlight, [this.annotation]);
}
