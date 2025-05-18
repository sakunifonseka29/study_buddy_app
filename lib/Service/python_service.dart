import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'remote_api_service.dart';

class PythonService {
  final RemoteAPIService _apiService = RemoteAPIService();

  /// Generate a study schedule - attempts remote API first, falls back to local Python script
  Future<bool> generateSchedule(String userId) async {
    // Try to use the remote API first (if available)
    if (await _isNetworkAvailable()) {
      try {
        final bool apiResult = await _apiService.generateScheduleFromAPI(
          userId,
        );
        if (apiResult) {
          debugPrint('Schedule generated via remote API');
          return true;
        }
      } catch (e) {
        debugPrint('Remote API failed, falling back to local script: $e');
        // Fall back to local script
      }
    }

    // If API call fails or network unavailable, try local Python script
    return await _runLocalPythonScript(userId);
  }

  /// Execute the schedule generator Python script locally
  Future<bool> _runLocalPythonScript(String userId) async {
    try {
      // Get the path to the Python script
      final scriptPath = path.join(
        Directory.current.path,
        'Py',
        'generate_schedule.py',
      );

      // Check if the script exists
      if (!await File(scriptPath).exists()) {
        debugPrint('Python script not found at: $scriptPath');
        return false;
      }

      // Run the Python script with the user ID as an argument
      final result = await Process.run('python', [scriptPath, userId]);

      // Check if the script executed successfully
      if (result.exitCode != 0) {
        debugPrint('Python script execution failed: ${result.stderr}');
        return false;
      }

      debugPrint('Python script output: ${result.stdout}');
      return true;
    } catch (e) {
      debugPrint('Error executing Python script: $e');
      return false;
    }
  }

  /// Check if network is available (basic check)
  Future<bool> _isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
