import 'dart:io';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Service/firebaseService.dart';
import 'package:study_buddy_app/Service/cloudinaryService.dart';

class UserService extends FirebaseService {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  Future<User?> getUser(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> createUser(User user) async {
    try {
      await usersCollection.doc(user.userId).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await usersCollection.doc(userId).update({'preferences': preferences});
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  Future<void> updateUserSubjects(String userId, List<String> subjects) async {
    try {
      await usersCollection.doc(userId).update({'subjects': subjects});
    } catch (e) {
      throw Exception('Failed to update subjects: $e');
    }
  }

  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      await usersCollection.doc(userId).update({'profileImageUrl': imageUrl});
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Upload to Cloudinary
      final imageUrl = await _cloudinaryService.uploadFile(
        file: imageFile,
        userId: userId,
        isProfileImage: true,
      );

      if (imageUrl != null) {
        // Update user profile in Firestore
        await updateProfileImage(userId, imageUrl);
        return imageUrl;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<List<User>> searchUsers(
    String query, {
    List<String> excludeIds = const [],
  }) async {
    try {
      if (query.length < 2) return [];

      // First search by name
      final querySnapshot =
          await usersCollection
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(10)
              .get();

      final results =
          querySnapshot.docs
              .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
              .where((user) => !excludeIds.contains(user.userId))
              .toList();

      // If we have less than 10 results, search by email as well
      if (results.length < 10) {
        final emailQuerySnapshot =
            await usersCollection
                .where('email', isGreaterThanOrEqualTo: query)
                .where('email', isLessThanOrEqualTo: '$query\uf8ff')
                .limit(10 - results.length)
                .get();

        final emailResults =
            emailQuerySnapshot.docs
                .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
                .where(
                  (user) =>
                      !excludeIds.contains(user.userId) &&
                      !results.any((u) => u.userId == user.userId),
                )
                .toList();

        results.addAll(emailResults);
      }

      return results;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
