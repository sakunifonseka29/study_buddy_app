class StudyGroup {
  final String groupId;
  final String groupName;
  final String subject;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime? nextSessionTime;
  final bool isPublic;
  final String? meetingLink;

  StudyGroup({
    required this.groupId,
    required this.groupName,
    required this.subject,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.createdAt,
    this.nextSessionTime,
    this.isPublic = true,
    this.meetingLink,
  });
  factory StudyGroup.fromMap(Map<String, dynamic> map) {
    return StudyGroup(
      groupId: map['groupId'],
      groupName: map['groupName'],
      subject: map['subject'],
      description: map['description'],
      creatorId: map['creatorId'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      nextSessionTime:
          map['nextSessionTime'] != null
              ? DateTime.parse(map['nextSessionTime'])
              : null,
      isPublic: map['isPublic'] ?? true,
      meetingLink: map['meetingLink'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'subject': subject,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'nextSessionTime': nextSessionTime?.toIso8601String(),
      'isPublic': isPublic,
      'meetingLink': meetingLink,
    };
  }
}
