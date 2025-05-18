import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // User collection reference
  CollectionReference get usersCollection => _firestore.collection('users');

  // Study groups collection reference
  CollectionReference get studyGroupsCollection =>
      _firestore.collection('studyGroups');

  // Schedules collection reference
  CollectionReference get schedulesCollection =>
      _firestore.collection('schedules');

  // Rewards collection reference
  CollectionReference get rewardsCollection => _firestore.collection('rewards');

  // Resources collection reference
  CollectionReference get resourcesCollection =>
      _firestore.collection('resources');

  // Notifications collection reference
  CollectionReference get notificationsCollection =>
      _firestore.collection('notifications');

  // Current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Authentication methods
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      await usersCollection.doc(userCredential.user?.uid).set({
        'userId': userCredential.user?.uid,
        'name': name,
        'email': email,
        'studyGroupIds': [],
        'subjects': [],
        'preferences': {},
        'totalPoints': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
