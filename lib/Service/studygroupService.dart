import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_buddy_app/Models/studygroupModel.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Service/firebaseService.dart';

class StudyGroupService extends FirebaseService {
  Future<StudyGroup> createStudyGroup({
    required String groupName,
    required String subject,
    required String description,
    required String creatorId,
    bool isPublic = true,
  }) async {
    try {
      final docRef = studyGroupsCollection.doc();
      final group = StudyGroup(
        groupId: docRef.id,
        groupName: groupName,
        subject: subject,
        description: description,
        creatorId: creatorId,
        memberIds: [creatorId],
        createdAt: DateTime.now(),
        isPublic: isPublic,
      );

      await docRef.set(group.toMap());

      // Add group to user's study groups
      await usersCollection.doc(creatorId).update({
        'studyGroupIds': FieldValue.arrayUnion([docRef.id]),
      });

      return group;
    } catch (e) {
      throw Exception('Failed to create study group: $e');
    }
  }

  Future<void> joinStudyGroup(String groupId, String userId) async {
    try {
      await studyGroupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      await usersCollection.doc(userId).update({
        'studyGroupIds': FieldValue.arrayUnion([groupId]),
      });
    } catch (e) {
      throw Exception('Failed to join study group: $e');
    }
  }

  Future<List<StudyGroup>> getUserStudyGroups(String userId) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (!userDoc.exists) return [];

      final user = User.fromMap(userDoc.data() as Map<String, dynamic>);
      if (user.studyGroupIds.isEmpty) return [];

      final groups =
          await studyGroupsCollection
              .where(FieldPath.documentId, whereIn: user.studyGroupIds)
              .get();

      return groups.docs
          .map((doc) => StudyGroup.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user study groups: $e');
    }
  }

  Future<List<StudyGroup>> searchPublicGroups(String query) async {
    try {
      final snapshot =
          await studyGroupsCollection
              .where('isPublic', isEqualTo: true)
              .where('groupName', isGreaterThanOrEqualTo: query)
              .where('groupName', isLessThanOrEqualTo: '$query\uf8ff')
              .get();

      return snapshot.docs
          .map((doc) => StudyGroup.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search study groups: $e');
    }
  }

  Future<void> updateMeetingLink(String groupId, String? meetingLink) async {
    try {
      await studyGroupsCollection.doc(groupId).update({
        'meetingLink': meetingLink,
      });
    } catch (e) {
      throw Exception('Failed to update meeting link: $e');
    }
  }

  Future<StudyGroup?> getStudyGroup(String groupId) async {
    try {
      final doc = await studyGroupsCollection.doc(groupId).get();
      if (!doc.exists) return null;

      return StudyGroup.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get study group: $e');
    }
  }
}
