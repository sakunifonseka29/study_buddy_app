import 'package:flutter/material.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _rewardItems = [];
  int _userPoints = 2500; // Mock user points for demonstration

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real scenario, you'd get the current user's ID
      // For demo purposes, we'll use a sample list of rewards
      _rewardItems = [
        // Regular rewards (unlocked based on achievements)
        {
          'id': 'streak7',
          'name': 'Study Streak Badge',
          'description': 'Complete tasks for 7 consecutive days',
          'points': 500,
          'icon': Icons.local_fire_department,
          'color': Colors.deepOrange,
          'unlocked': true,
          'claimed': true,
          'type': 'achievement',
        },
        {
          'id': 'explorer',
          'name': 'Knowledge Explorer',
          'description': 'Complete 10 different subject tasks',
          'points': 750,
          'icon': Icons.explore,
          'color': Colors.blue,
          'unlocked': true,
          'claimed': true,
          'type': 'achievement',
        },
        {
          'id': 'top3',
          'name': 'Top 3 Finisher',
          'description': 'Rank in the top 3 of the monthly leaderboard',
          'points': 1000,
          'icon': Icons.emoji_events,
          'color': Colors.amber,
          'unlocked': false,
          'claimed': false,
          'type': 'achievement',
        },

        // Premium rewards (can be claimed with points)
        {
          'id': 'premium1',
          'name': 'Premium Study Materials',
          'description': 'Access to exclusive study materials for a month',
          'points': 1800,
          'icon': Icons.book,
          'color': Colors.purple,
          'unlocked': _userPoints >= 1800,
          'claimed': false,
          'type': 'claimable',
        },
        {
          'id': 'premium2',
          'name': 'Private Tutor Session',
          'description': 'One hour session with an expert tutor of your choice',
          'points': 2500,
          'icon': Icons.school,
          'color': Colors.teal,
          'unlocked': _userPoints >= 2500,
          'claimed': false,
          'type': 'claimable',
        },
        {
          'id': 'premium3',
          'name': 'AI Study Assistant',
          'description': 'Unlock AI-powered study assistant for homework help',
          'points': 2000,
          'icon': Icons.smartphone,
          'color': Colors.indigo,
          'unlocked': _userPoints >= 2000,
          'claimed': false,
          'type': 'claimable',
        },
        {
          'id': 'premium4',
          'name': 'Exclusive Study Template Pack',
          'description': 'Premium note-taking and study planning templates',
          'points': 1950,
          'icon': Icons.article,
          'color': Colors.green,
          'unlocked': _userPoints >= 1950,
          'claimed': false,
          'type': 'claimable',
        },
        {
          'id': 'group_master',
          'name': 'Group Master',
          'description': 'Create a study group with at least 5 active members',
          'points': 800,
          'icon': Icons.group,
          'color': Colors.green,
          'unlocked': false,
          'claimed': false,
          'type': 'achievement',
        },
        {
          'id': 'perfect_scheduler',
          'name': 'Perfect Scheduler',
          'description': 'Complete all scheduled tasks for a week',
          'points': 600,
          'icon': Icons.calendar_today,
          'color': Colors.purple,
          'unlocked': false,
          'claimed': false,
          'type': 'achievement',
        },
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading rewards: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading rewards: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _claimReward(Map<String, dynamic> reward) {
    // In a real app, you'd call an API to claim the reward
    setState(() {
      // Find the reward and update it
      final index = _rewardItems.indexWhere((r) => r['id'] == reward['id']);
      if (index != -1) {
        _rewardItems[index]['claimed'] = true;
        _userPoints -= reward['points'] as int;
      }
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully claimed ${reward['name']}!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.deepPurple,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Rewards',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Spacer(),
                  // Points counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars,
                          size: 16,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_userPoints pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Header with explanation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Study Rewards',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Earn points by completing tasks, participating in study groups, and maintaining your schedule. Unlock rewards as you reach point milestones!',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ), // Rewards categories
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                      'All Rewards',
                      Icons.card_giftcard,
                      isSelected: true,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      'Claimable',
                      Icons.redeem,
                      isSelected: false,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      'Achievements',
                      Icons.emoji_events_outlined,
                      isSelected: false,
                    ),
                  ],
                ),
              ),
            ),

            // Rewards content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildRewardsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    IconData icon, {
    required bool isSelected,
  }) {
    return Chip(
      backgroundColor: isSelected ? Colors.deepPurple : Colors.grey.shade100,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsContent() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: _rewardItems.length,
      itemBuilder: (context, index) {
        final reward = _rewardItems[index];
        final bool isUnlocked = reward['unlocked'] as bool;
        final bool isClaimed = reward['claimed'] as bool;
        final bool isClaimable = reward['type'] == 'claimable';

        final Color baseColor = reward['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color:
                  isUnlocked
                      ? baseColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Show reward details in a bottom sheet
                  _showRewardDetails(context, reward);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Reward icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              isUnlocked
                                  ? baseColor.withOpacity(0.15)
                                  : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              reward['icon'] as IconData,
                              size: 30,
                              color: isUnlocked ? baseColor : Colors.grey,
                            ),
                            if (isClaimed)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Reward info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reward['name'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isUnlocked
                                              ? Colors.black87
                                              : Colors.grey,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isUnlocked
                                            ? baseColor.withOpacity(0.15)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${reward['points']} pts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isUnlocked ? baseColor : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reward['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isUnlocked
                                        ? Colors.grey.shade700
                                        : Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Status indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isUnlocked
                                          ? isClaimed
                                              ? Icons.check_circle
                                              : Icons.stars
                                          : Icons.lock,
                                      size: 16,
                                      color:
                                          isUnlocked
                                              ? isClaimed
                                                  ? Colors.green
                                                  : baseColor
                                              : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isUnlocked
                                          ? isClaimed
                                              ? 'Claimed'
                                              : 'Available'
                                          : 'Locked',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isUnlocked
                                                ? isClaimed
                                                    ? Colors.green
                                                    : baseColor
                                                : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                                // Claim button for premium rewards
                                if (isClaimable && isUnlocked && !isClaimed)
                                  ElevatedButton(
                                    onPressed: () => _claimReward(reward),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: baseColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Claim',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRewardDetails(BuildContext context, Map<String, dynamic> reward) {
    final isUnlocked = reward['unlocked'] as bool;
    final isClaimed = reward['claimed'] as bool;
    final isClaimable = reward['type'] == 'claimable';
    final baseColor = reward['color'] as Color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Reward icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        reward['icon'] as IconData,
                        size: 60,
                        color: isUnlocked ? baseColor : Colors.grey,
                      ),
                      if (isClaimed)
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Reward name
                Text(
                  reward['name'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Points
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${reward['points']} points',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: baseColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description title
                Text(
                  isClaimable ? 'Reward Details:' : 'How to earn this reward:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  reward['description'] as String,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUnlocked
                          ? isClaimed
                              ? Icons.check_circle
                              : Icons.stars
                          : Icons.lock,
                      color:
                          isUnlocked
                              ? isClaimed
                                  ? Colors.green
                                  : baseColor
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUnlocked
                          ? isClaimed
                              ? 'You have claimed this reward!'
                              : 'You have unlocked this reward!'
                          : 'Keep earning points to unlock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color:
                            isUnlocked
                                ? isClaimed
                                    ? Colors.green
                                    : baseColor
                                : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Claim or Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isClaimable && isUnlocked && !isClaimed) {
                        _claimReward(reward);
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isClaimable && isUnlocked && !isClaimed
                              ? baseColor
                              : Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      isClaimable && isUnlocked && !isClaimed
                          ? 'Claim Reward'
                          : 'Close',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
