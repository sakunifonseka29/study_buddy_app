import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:study_buddy_app/config/api_config.dart';

class RemoteAPIService {
  // Get base URL from configuration dynamically each time
  String get baseUrl => APIConfig.baseUrl;
  // Method to generate schedule using Flask endpoint
  Future<bool> generateScheduleFromAPI(String userId) async {
    try {
      debugPrint('Calling Flask API to generate schedule for user: $userId');
      final response = await http.post(
        Uri.parse('$baseUrl/generate-schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('API response: $responseData');
        return true;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Network error: $e');
      return false;
    }
  }

  // Check if API server is reachable
  Future<bool> isServerReachable() async {
    try {
      // Use a specific health check endpoint or just /
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (e) {
      debugPrint('Server unreachable: $e');
      return false;
    }
  }

  // Try to reconnect with multiple attempts
  Future<bool> attemptReconnection({int maxAttempts = 3}) async {
    debugPrint('Attempting reconnection to API server...');
    for (int i = 0; i < maxAttempts; i++) {
      debugPrint('Attempt ${i + 1} of $maxAttempts');
      if (await isServerReachable()) {
        debugPrint('Successfully reconnected to API server');
        return true;
      }
      // Wait a bit before retrying
      await Future.delayed(Duration(seconds: 2));
    }
    debugPrint('Failed to reconnect after $maxAttempts attempts');
    return false;
  }

  // Fetch schedule data directly (alternative approach)
  Future<List<Map<String, dynamic>>?> fetchUserSchedule(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-schedules/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Network error: $e');
      return null;
    }
  }
}
