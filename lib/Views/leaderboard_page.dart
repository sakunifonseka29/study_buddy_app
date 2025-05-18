import 'package:flutter/material.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Service/rewardService.dart';
import 'package:study_buddy_app/Service/demo_data_service.dart';
import 'package:study_buddy_app/Views/rewards_page.dart';
import 'package:intl/intl.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final RewardService _rewardService = RewardService();
  final DemoDataService _demoDataService = DemoDataService();
  bool _isLoading = true;
  List<User> _topUsers = [];
  String _currentMonth = '';

  @override
  void initState() {
    super.initState();
    _setupAndLoadLeaderboard();
    _currentMonth = _getCurrentMonth();
  }

  String _getCurrentMonth() {
    return DateFormat('MMMM yyyy').format(DateTime.now());
  }

  Future<void> _setupAndLoadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First generate demo data if needed
      await _demoDataService.generateDemoUsersIfNeeded();

      // Now load the leaderboard
      await _loadLeaderboardData();
    } catch (e) {
      print("Error in setup: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up leaderboard: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadLeaderboardData() async {
    try {
      // Get leaderboard data
      final users = await _rewardService.getLeaderboard();
      print("Fetched ${users.length} users for leaderboard");
      for (var user in users.take(3)) {
        print("User ${user.name} - Points: ${user.totalPoints}");
      }

      setState(() {
        _topUsers = users.take(10).toList(); // Get top 10 users
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching leaderboard: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading leaderboard: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    'Leaderboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "This month's hard working buddies",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Leaderboard Content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildLeaderboardContent(),
            ),

            // Rewards button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Work hard and win rewards",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RewardsPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'View Rewards',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    if (_topUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              "No users on the leaderboard yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Complete tasks to earn points",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _topUsers.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _topUsers[index];
        final isTopThree = index < 3;

        return Container(
          margin: EdgeInsets.symmetric(vertical: isTopThree ? 8 : 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isTopThree ? Colors.deepPurple.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                isTopThree
                    ? Border.all(
                      color:
                          index == 0
                              ? Colors.amber.withOpacity(0.5)
                              : index == 1
                              ? Colors.grey.shade400.withOpacity(0.5)
                              : Colors.brown.shade300.withOpacity(0.5),
                      width: 1,
                    )
                    : null,
            boxShadow:
                isTopThree
                    ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              // Rank indicator with crown for first place
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getRankColor(index),
                  shape: BoxShape.circle,
                  boxShadow:
                      isTopThree
                          ? [
                            BoxShadow(
                              color: _getRankColor(index).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                          : null,
                ),
                alignment: Alignment.center,
                child:
                    index == 0
                        ? const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 20,
                        )
                        : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
              const SizedBox(width: 16),

              // User avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                child:
                    user.profileImageUrl == null
                        ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isTopThree
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (index == 0)
                          const Icon(
                            Icons.military_tech,
                            color: Colors.amber,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.totalPoints} points',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight:
                            isTopThree ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // Points badge for top 3
              if (isTopThree)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRankColor(index).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 16, color: _getRankColor(index)),
                      const SizedBox(width: 4),
                      Text(
                        user.totalPoints.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRankColor(index),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold for 1st
      case 1:
        return const Color(0xFFC0C0C0); // Silver for 2nd
      case 2:
        return const Color(0xFFCD7F32); // Bronze for 3rd
      default:
        return Colors.grey.shade600;
    }
  }
}
