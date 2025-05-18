import 'dart:async';
import 'package:flutter/material.dart';
import 'package:study_buddy_app/Service/monthly_reward_service.dart';

class BackgroundTaskService {
  static final BackgroundTaskService _instance =
      BackgroundTaskService._internal();

  factory BackgroundTaskService() => _instance;

  BackgroundTaskService._internal();

  final MonthlyRewardService _monthlyRewardService = MonthlyRewardService();
  Timer? _dailyCheckTimer;

  // Start the background task service
  void startBackgroundTasks() {
    // Check immediately on app start
    _checkMonthlyResetTask();

    // Schedule daily checks at midnight
    _scheduleDailyCheck();
  }

  // Schedule a daily check at midnight
  void _scheduleDailyCheck() {
    // Cancel any existing timer
    _dailyCheckTimer?.cancel();

    // Calculate time until next midnight
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    debugPrint(
      'Scheduled next monthly reset check in ${timeUntilMidnight.inHours} hours and ${timeUntilMidnight.inMinutes % 60} minutes',
    );

    // Schedule the first check at midnight
    _dailyCheckTimer = Timer(timeUntilMidnight, () {
      _checkMonthlyResetTask();

      // Then schedule it to run daily
      _dailyCheckTimer = Timer.periodic(const Duration(days: 1), (timer) {
        _checkMonthlyResetTask();
      });
    });
  }

  // Task to check for monthly reset
  Future<void> _checkMonthlyResetTask() async {
    try {
      debugPrint('Running scheduled monthly reset check');
      final resetProcessed =
          await _monthlyRewardService.checkAndProcessMonthlyReset();

      if (resetProcessed) {
        debugPrint('Monthly points reset was successfully processed!');
      } else {
        debugPrint('No monthly points reset needed at this time.');
      }
    } catch (e) {
      debugPrint('Error in scheduled monthly reset check: $e');
    }
  }

  // Stop background tasks
  void stopBackgroundTasks() {
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = null;
  }
}
