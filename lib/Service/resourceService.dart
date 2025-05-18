import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_buddy_app/Models/studyresaurceModel.dart';
import 'package:study_buddy_app/Service/firebaseservice.dart';

class ResourceService extends FirebaseService {
  Future<StudyResource> addResource({
    required String title,
    required String subject,
    required String description,
    required String url,
    required String resourceType,
    required String uploaderId,
    required List<String> tags,
  }) async {
    try {
      final docRef = resourcesCollection.doc();
      final resource = StudyResource(
        resourceId: docRef.id,
        title: title,
        subject: subject,
        description: description,
        url: url,
        resourceType: resourceType,
        uploaderId: uploaderId,
        uploadDate: DateTime.now(),
        tags: tags,
      );

      await docRef.set(resource.toMap());
      return resource;
    } catch (e) {
      throw Exception('Failed to add resource: $e');
    }
  }

  Future<List<StudyResource>> getResourcesBySubject(String subject) async {
    try {
      final snapshot =
          await resourcesCollection
              .where('subject', isEqualTo: subject)
              .orderBy('uploadDate', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) => StudyResource.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get resources by subject: $e');
    }
  }

  Future<void> upvoteResource(String resourceId) async {
    try {
      await resourcesCollection.doc(resourceId).update({
        'upvotes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to upvote resource: $e');
    }
  }
}
