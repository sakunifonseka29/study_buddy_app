// Helper class for schedule items
class TaskSchedule {
  final String subject;
  final String description;
  final String time;
  final bool isGroup;
  final String? notes;
  final String? location;

  TaskSchedule({
    required this.subject,
    required this.description,
    required this.time,
    this.isGroup = false,
    this.notes,
    this.location,
  });

  // Create a copy with modified fields
  TaskSchedule copyWith({
    String? subject,
    String? description,
    String? time,
    bool? isGroup,
    String? notes,
    String? location,
  }) {
    return TaskSchedule(
      subject: subject ?? this.subject,
      description: description ?? this.description,
      time: time ?? this.time,
      isGroup: isGroup ?? this.isGroup,
      notes: notes ?? this.notes,
      location: location ?? this.location,
    );
  }
}
