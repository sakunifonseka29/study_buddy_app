class StudyResource {
  final String resourceId;
  final String title;
  final String subject;
  final String description;
  final String url;
  final String resourceType; // pdf, video, website, etc.
  final String uploaderId;
  final DateTime uploadDate;
  final int upvotes;
  final List<String> tags;

  StudyResource({
    required this.resourceId,
    required this.title,
    required this.subject,
    required this.description,
    required this.url,
    required this.resourceType,
    required this.uploaderId,
    required this.uploadDate,
    this.upvotes = 0,
    required this.tags,
  });

  factory StudyResource.fromMap(Map<String, dynamic> map) {
    return StudyResource(
      resourceId: map['resourceId'],
      title: map['title'],
      subject: map['subject'],
      description: map['description'],
      url: map['url'],
      resourceType: map['resourceType'],
      uploaderId: map['uploaderId'],
      uploadDate: DateTime.parse(map['uploadDate']),
      upvotes: map['upvotes'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resourceId': resourceId,
      'title': title,
      'subject': subject,
      'description': description,
      'url': url,
      'resourceType': resourceType,
      'uploaderId': uploaderId,
      'uploadDate': uploadDate.toIso8601String(),
      'upvotes': upvotes,
      'tags': tags,
    };
  }
}
