import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_buddy_app/Models/monthly_reward_model.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Service/firebaseService.dart';
import 'package:intl/intl.dart';

class MonthlyRewardService extends FirebaseService {
  // Collection reference for monthly rewards
  final CollectionReference monthlyRewardsCollection = FirebaseFirestore
      .instance
      .collection('monthly_rewards');

  // Collection reference for system settings
  final CollectionReference systemSettingsCollection = FirebaseFirestore
      .instance
      .collection('system_settings');

  // Get current month-year string for storage
  String getCurrentMonthYear() {
    final now = DateTime.now();
    return DateFormat('MM-yyyy').format(now);
  }

  // Check if monthly reset needs to be processed
  Future<bool> checkAndProcessMonthlyReset() async {
    try {
      // Get current date
      final now = DateTime.now();
      final currentDay = now.day;
      final currentMonthYear = getCurrentMonthYear();

      // Only process on the first day of the month
      if (currentDay == 1) {
        // Check if we've already processed this month
        final checkDoc =
            await systemSettingsCollection.doc('lastMonthlyReset').get();

        if (checkDoc.exists) {
          final data = checkDoc.data() as Map<String, dynamic>?;
          final lastReset = data?['lastResetMonth'];
          if (lastReset == currentMonthYear) {
            print('Monthly reset already processed for $currentMonthYear');
            return false;
          }
        }

        // Process the monthly rewards
        await processMonthlyRewards();

        // Update the last reset record
        await systemSettingsCollection.doc('lastMonthlyReset').set({
          'lastResetMonth': currentMonthYear,
          'processedAt': FieldValue.serverTimestamp(),
        });

        return true;
      }
      return false;
    } catch (e) {
      print('Error checking monthly reset: $e');
      throw Exception('Failed to check monthly reset: $e');
    }
  }

  // Reset points at the beginning of a new month
  Future<void> processMonthlyRewards() async {
    try {
      final currentMonthYear = getCurrentMonthYear();

      // Check if we've already processed this month
      final existingRewards =
          await monthlyRewardsCollection
              .where('monthYear', isEqualTo: currentMonthYear)
              .limit(1)
              .get();

      if (existingRewards.docs.isNotEmpty) {
        // Already processed this month
        return;
      }

      // Get top users by points for the month
      final leaderboard =
          await getMonthlyLeaderboard(); // Create monthly reward records and reset user points
      int rank = 1;
      for (var user in leaderboard) {
        // Create monthly reward record
        final docRef = monthlyRewardsCollection.doc();
        final reward = MonthlyReward(
          rewardId: docRef.id,
          userId: user.userId,
          monthPoints: user.totalPoints,
          rank: rank,
          monthYear: currentMonthYear,
          createdAt: DateTime.now(),
        );

        await docRef.set(reward.toMap());

        // Reset user points
        await usersCollection.doc(user.userId).update({'totalPoints': 0});

        rank++;
      }
    } catch (e) {
      throw Exception('Failed to process monthly rewards: $e');
    }
  }

  // Get the leaderboard for the current month
  Future<List<User>> getMonthlyLeaderboard() async {
    try {
      final snapshot =
          await usersCollection
              .orderBy('totalPoints', descending: true)
              .limit(10)
              .get();

      return snapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get monthly leaderboard: $e');
    }
  }

  // Get previous month's rewards
  Future<List<MonthlyReward>> getPreviousMonthRewards() async {
    try {
      // Get previous month
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      final previousMonthYear = DateFormat('MM-yyyy').format(previousMonth);

      final snapshot =
          await monthlyRewardsCollection
              .where('monthYear', isEqualTo: previousMonthYear)
              .orderBy('rank')
              .limit(10)
              .get();

      return snapshot.docs
          .map(
            (doc) => MonthlyReward.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get previous month rewards: $e');
    }
  }
}
