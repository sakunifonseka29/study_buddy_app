import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/Service/authStateClearService.dart';

class AuthService {
  static AuthService? _instance;
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  // Private constructor for singleton
  AuthService._();

  // Factory constructor
  factory AuthService() {
    _instance ??= AuthService._();
    return _instance!;
  }

  // Get current user
  auth.User? get currentUser => _firebaseAuth.currentUser;

  // Get auth state changes
  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with email and password
  Future<auth.UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Create new user with email and password
  Future<auth.UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // We'll let the SubjectPreferencePage create and save the user document
      // This just creates the authentication account

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Global sign out method that also clears the app state
  static Future<void> signOutAndClearState(ProviderContainer container) async {
    // Clear all cached state
    AuthStateClearService.clearUserState(container);

    // Sign out the user
    await _instance?.signOut();
  }

  // Password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
