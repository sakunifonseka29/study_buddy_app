class AppNotification {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final String notificationType; // reminder, points, group, etc.
  final Map<String, dynamic>? payload; // Additional data

  AppNotification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.notificationType,
    this.payload,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      notificationId: map['notificationId'],
      userId: map['userId'],
      title: map['title'],
      message: map['message'],
      time: DateTime.parse(map['time']),
      isRead: map['isRead'] ?? false,
      notificationType: map['notificationType'],
      payload:
          map['payload'] != null
              ? Map<String, dynamic>.from(map['payload'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'time': time.toIso8601String(),
      'isRead': isRead,
      'notificationType': notificationType,
      'payload': payload,
    };
  }
}
