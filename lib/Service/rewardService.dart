import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_buddy_app/Models/rewordsModel.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Service/firebaseService.dart';

class RewardService extends FirebaseService {
  Future<RewardPoint> addPoints({
    required String userId,
    required int points,
    required String reason,
    String? relatedActivityId,
  }) async {
    try {
      final docRef = rewardsCollection.doc();
      final reward = RewardPoint(
        pointId: docRef.id,
        userId: userId,
        points: points,
        reason: reason,
        dateEarned: DateTime.now(),
        relatedActivityId: relatedActivityId,
      );

      await docRef.set(reward.toMap());

      // Update user's total points
      await usersCollection.doc(userId).update({
        'totalPoints': FieldValue.increment(points),
      });

      return reward;
    } catch (e) {
      throw Exception('Failed to add points: $e');
    }
  }

  Future<List<RewardPoint>> getUserRewards(String userId) async {
    try {
      final snapshot =
          await rewardsCollection
              .where('userId', isEqualTo: userId)
              .orderBy('dateEarned', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => RewardPoint.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user rewards: $e');
    }
  }

  Future<List<User>> getLeaderboard() async {
    try {
      final snapshot =
          await usersCollection
              .orderBy('totalPoints', descending: true)
              .limit(50)
              .get();

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              // Add null checks for required String fields
              return User.fromMap(data);
            } catch (e) {
              print("Error mapping user document ${doc.id}: $e");
              return null; // Skip this user
            }
          })
          .whereType<User>() // Filter out nulls
          .toList();
    } catch (e) {
      print("Error in getLeaderboard: $e");
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  // Get points earned per day for the last week
  // Returns a map with day of week as key (0 = Monday, 6 = Sunday) and points as value
  Future<Map<int, int>> getUserPointsLastWeek(String userId) async {
    try {
      // Calculate start of the week (Monday 12:00 AM)
      DateTime now = DateTime.now();
      DateTime startOfWeek = _getStartOfWeek(now);

      // Get rewards from the past week
      final snapshot =
          await rewardsCollection
              .where('userId', isEqualTo: userId)
              .where(
                'dateEarned',
                isGreaterThanOrEqualTo: startOfWeek.toIso8601String(),
              )
              .orderBy('dateEarned')
              .get();

      // Group points by day of week (0 = Monday, 6 = Sunday)
      final Map<int, int> pointsByDay = {
        0: 0,
        1: 0,
        2: 0,
        3: 0,
        4: 0,
        5: 0,
        6: 0,
      };

      // Process each reward
      final rewards =
          snapshot.docs
              .map(
                (doc) =>
                    RewardPoint.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      for (var reward in rewards) {
        // Get the day of the week (0 = Monday, 6 = Sunday)
        int dayOfWeek = reward.dateEarned.weekday - 1;

        // Add the points to the corresponding day
        pointsByDay[dayOfWeek] = (pointsByDay[dayOfWeek] ?? 0) + reward.points;
      }

      return pointsByDay;
    } catch (e) {
      throw Exception('Failed to get user points for the week: $e');
    }
  }

  // Helper method to get the start of the current week (Monday 12:00 AM)
  DateTime _getStartOfWeek(DateTime date) {
    // Find the most recent Monday
    int daysToSubtract = date.weekday - 1;
    DateTime startOfWeek = date.subtract(
      Duration(
        days: daysToSubtract,
        hours: date.hour,
        minutes: date.minute,
        seconds: date.second,
        milliseconds: date.millisecond,
        microseconds: date.microsecond,
      ),
    );

    return startOfWeek;
  }
}
