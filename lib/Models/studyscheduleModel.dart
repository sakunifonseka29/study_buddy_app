class StudySchedule {
  final String scheduleId;
  final String userId;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCompleted;
  final bool isGroupSession;
  final String? groupId;
  final String? taskDescription;
  final String? reminderId;

  StudySchedule({
    required this.scheduleId,
    required this.userId,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    this.isGroupSession = false,
    this.groupId,
    this.taskDescription,
    this.reminderId,
  });

  factory StudySchedule.fromMap(Map<String, dynamic> map) {
    return StudySchedule(
      scheduleId: map['scheduleId'] ?? '',
      userId: map['userId'] ?? '',
      subject: map['subject'] ?? '',
      startTime:
          map['startTime'] is String
              ? DateTime.parse(map['startTime'])
              : map['startTime'].toDate(),
      endTime:
          map['endTime'] is String
              ? DateTime.parse(map['endTime'])
              : map['endTime'].toDate(),
      isCompleted: map['isCompleted'] ?? false,
      isGroupSession: map['isGroupSession'] ?? false,
      groupId: map['groupId'],
      taskDescription: map['taskDescription'],
      reminderId: map['reminderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'userId': userId,
      'subject': subject,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isCompleted': isCompleted,
      'isGroupSession': isGroupSession,
      'groupId': groupId,
      'taskDescription': taskDescription,
      'reminderId': reminderId,
    };
  }
}
