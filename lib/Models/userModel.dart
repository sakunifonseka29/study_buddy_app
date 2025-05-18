class User {
  final String userId;
  final String name;
  final String email;
  final String? profileImageUrl;
  final List<String> studyGroupIds;
  final List<String> subjects;
  final Map<String, dynamic> preferences;
  final int totalPoints;
  final DateTime createdAt;

  User({
    required this.userId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.studyGroupIds,
    required this.subjects,
    required this.preferences,
    required this.totalPoints,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'],
      name: map['name'],
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
      studyGroupIds: List<String>.from(map['studyGroupIds'] ?? []),
      subjects: List<String>.from(map['subjects'] ?? []),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      totalPoints: map['totalPoints'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'studyGroupIds': studyGroupIds,
      'subjects': subjects,
      'preferences': preferences,
      'totalPoints': totalPoints,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
