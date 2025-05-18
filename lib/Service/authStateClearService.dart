import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/providerService.dart';

/// Service to clear cached state when authentication changes
class AuthStateClearService {
  /// Clear all user-related cached state when user logs out
  static void clearUserState(ProviderContainer container) {
    // Invalidate the user data provider to force fresh data fetch
    container.refresh(currentUserDataProvider);

    // Invalidate any other user-dependent providers
    container.refresh(userTasksProvider);
    container.refresh(userOngoingTasksProvider);
    container.refresh(weeklyPointsProvider);
    container.refresh(userStudyGroupsProvider);
    container.refresh(leaderboardProvider);
  }
}
