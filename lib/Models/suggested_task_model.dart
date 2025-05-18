import 'package:cloud_firestore/cloud_firestore.dart';

class SuggestedTask {
  final String id;
  final String title;
  final String description;
  final String subject;
  final int xpPoints;
  final int difficultyLevel;

  SuggestedTask({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.xpPoints,
    required this.difficultyLevel,
  });

  factory SuggestedTask.fromMap(Map<String, dynamic> map) {
    return SuggestedTask(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      subject: map['subject'],
      xpPoints: map['xpPoints'],
      difficultyLevel: map['difficultyLevel'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'xpPoints': xpPoints,
      'difficultyLevel': difficultyLevel,
    };
  }

  SuggestedTask copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    int? xpPoints,
    int? difficultyLevel,
  }) {
    return SuggestedTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      xpPoints: xpPoints ?? this.xpPoints,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    );
  }
}
