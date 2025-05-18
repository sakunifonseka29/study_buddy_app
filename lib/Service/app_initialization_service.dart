import 'package:flutter/material.dart';
import 'package:study_buddy_app/Service/monthly_reward_service.dart';
import 'package:study_buddy_app/Service/background_task_service.dart';
import 'package:study_buddy_app/Service/cloudinarySetupService.dart';

class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();

  factory AppInitializationService() => _instance;

  AppInitializationService._internal();

  final MonthlyRewardService _monthlyRewardService = MonthlyRewardService();
  final BackgroundTaskService _backgroundTaskService = BackgroundTaskService();
  // Initialize app services
  Future<void> initialize() async {
    try {
      // Check and process monthly reset if needed
      await _checkMonthlyReset();

      // Check Cloudinary configuration
      _checkCloudinarySetup();

      // Start background tasks for scheduled checks
      _backgroundTaskService.startBackgroundTasks();
    } catch (e) {
      debugPrint('Error during app initialization: $e');
    }
  }

  // Check if Cloudinary is properly configured
  void _checkCloudinarySetup() {
    final isConfigured = CloudinarySetupService.isCloudinaryConfigured();
    if (!isConfigured) {
      debugPrint('⚠️ WARNING: Cloudinary is not properly configured.');
      debugPrint(
        '📝 See lib/config/cloudinary_setup.md for setup instructions.',
      );
    }
  }

  // Check if monthly reset is needed and process it
  Future<void> _checkMonthlyReset() async {
    try {
      final bool wasResetProcessed =
          await _monthlyRewardService.checkAndProcessMonthlyReset();

      if (wasResetProcessed) {
        debugPrint('Monthly points reset was successfully processed!');
      } else {
        debugPrint('No monthly points reset needed at this time.');
      }
    } catch (e) {
      debugPrint('Error checking monthly reset: $e');
    }
  }
}
