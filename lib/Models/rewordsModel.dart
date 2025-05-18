class RewardPoint {
  final String pointId;
  final String userId;
  final int points;
  final String reason;
  final DateTime dateEarned;
  final String? relatedActivityId; // Could be scheduleId or groupId

  RewardPoint({
    required this.pointId,
    required this.userId,
    required this.points,
    required this.reason,
    required this.dateEarned,
    this.relatedActivityId,
  });

  factory RewardPoint.fromMap(Map<String, dynamic> map) {
    return RewardPoint(
      pointId: map['pointId'],
      userId: map['userId'],
      points: map['points'],
      reason: map['reason'],
      dateEarned: DateTime.parse(map['dateEarned']),
      relatedActivityId: map['relatedActivityId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pointId': pointId,
      'userId': userId,
      'points': points,
      'reason': reason,
      'dateEarned': dateEarned.toIso8601String(),
      'relatedActivityId': relatedActivityId,
    };
  }
}
