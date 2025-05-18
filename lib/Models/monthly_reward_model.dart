class MonthlyReward {
  final String rewardId;
  final String userId;
  final int monthPoints;
  final int rank;
  final String monthYear; // Format: "MM-YYYY"
  final DateTime createdAt;

  MonthlyReward({
    required this.rewardId,
    required this.userId,
    required this.monthPoints,
    required this.rank,
    required this.monthYear,
    required this.createdAt,
  });

  factory MonthlyReward.fromMap(Map<String, dynamic> map) {
    return MonthlyReward(
      rewardId: map['rewardId'],
      userId: map['userId'],
      monthPoints: map['monthPoints'],
      rank: map['rank'],
      monthYear: map['monthYear'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rewardId': rewardId,
      'userId': userId,
      'monthPoints': monthPoints,
      'rank': rank,
      'monthYear': monthYear,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
