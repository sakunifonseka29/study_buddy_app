import 'package:flutter/material.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Service/firebaseService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoDataService extends FirebaseService {
  // Generate sample users with points for demonstration
  Future<void> generateDemoUsersIfNeeded() async {
    try {
      // Check if we already have users
      final snapshot = await usersCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print("Users exist, no need to generate demo data");
        return;
      }

      print("Generating demo users...");
      final demoUsers = [
        {
          'userId': 'user1',
          'name': 'Alex Johnson',
          'email': 'alex@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['Mathematics', 'Physics'],
          'preferences': {'theme': 'light'},
          'totalPoints': 850,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'user2',
          'name': 'Jamie Smith',
          'email': 'jamie@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['Biology', 'Chemistry'],
          'preferences': {'theme': 'dark'},
          'totalPoints': 720,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'user3',
          'name': 'Casey Taylor',
          'email': 'casey@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['History', 'Literature'],
          'preferences': {'theme': 'light'},
          'totalPoints': 650,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'user4',
          'name': 'Jordan Wilson',
          'email': 'jordan@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['Computer Science', 'Mathematics'],
          'preferences': {'theme': 'dark'},
          'totalPoints': 580,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'user5',
          'name': 'Riley Brown',
          'email': 'riley@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['Economics', 'Statistics'],
          'preferences': {'theme': 'light'},
          'totalPoints': 510,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'user6',
          'name': 'Drew Martinez',
          'email': 'drew@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['Art', 'Design'],
          'preferences': {'theme': 'dark'},
          'totalPoints': 430,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'user7',
          'name': 'Morgan Lee',
          'email': 'morgan@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['Psychology', 'Sociology'],
          'preferences': {'theme': 'light'},
          'totalPoints': 380,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'user8',
          'name': 'Taylor Clark',
          'email': 'taylor@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['Physics', 'Chemistry'],
          'preferences': {'theme': 'dark'},
          'totalPoints': 320,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'user9',
          'name': 'Avery White',
          'email': 'avery@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['Geography', 'History'],
          'preferences': {'theme': 'light'},
          'totalPoints': 250,
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'user10',
          'name': 'Cameron Davis',
          'email': 'cameron@example.com',
          'profileImageUrl': null,
          'studyGroupIds': <String>[],
          'subjects': ['Languages', 'Literature'],
          'preferences': {'theme': 'dark'},
          'totalPoints': 190,
          'createdAt': DateTime.now().toIso8601String(),
        },
      ];

      // Add users to Firestore
      final batch = FirebaseFirestore.instance.batch();
      for (var userData in demoUsers) {
        final docRef = usersCollection.doc(userData['userId'] as String);
        batch.set(docRef, userData);
      }

      await batch.commit();
      print("Created ${demoUsers.length} demo users");
    } catch (e) {
      print("Error generating demo users: $e");
    }
  }
}
