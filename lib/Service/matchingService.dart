import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Service/firebaseService.dart';

class MatchingService extends FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Find potential study buddies based on subjects of interest and preferences
  Future<List<User>> findPotentialMatches(
    String userId,
    List<String> subjects,
  ) async {
    try {
      // Get users with matching subjects
      final querySnapshot =
          await usersCollection
              .where('subjects', arrayContainsAny: subjects)
              .where('userId', isNotEqualTo: userId)
              .limit(10)
              .get();

      return querySnapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to find matches: $e');
    }
  }

  // Send a connection request to another user
  Future<void> sendConnectionRequest(String fromUserId, String toUserId) async {
    try {
      // First check if there's already a connection or request
      final existingRequestDoc =
          await _firestore
              .collection('connectionRequests')
              .where('fromUserId', isEqualTo: fromUserId)
              .where('toUserId', isEqualTo: toUserId)
              .limit(1)
              .get();

      if (existingRequestDoc.docs.isNotEmpty) {
        throw Exception('A connection request already exists');
      }

      // Create a new connection request
      await _firestore.collection('connectionRequests').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send connection request: $e');
    }
  }

  // Accept a connection request
  Future<void> acceptConnectionRequest(String requestId) async {
    try {
      // Get the request document
      final requestDoc =
          await _firestore
              .collection('connectionRequests')
              .doc(requestId)
              .get();

      if (!requestDoc.exists) {
        throw Exception('Connection request not found');
      }

      final requestData = requestDoc.data() as Map<String, dynamic>;
      final fromUserId = requestData['fromUserId'];
      final toUserId = requestData['toUserId'];

      // Create a connection
      await _firestore.collection('connections').add({
        'users': [fromUserId, toUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the request status
      await requestDoc.reference.update({'status': 'accepted'});

      // Update user records to reflect the connection
      await usersCollection.doc(fromUserId).update({
        'connections': FieldValue.arrayUnion([toUserId]),
      });

      await usersCollection.doc(toUserId).update({
        'connections': FieldValue.arrayUnion([fromUserId]),
      });
    } catch (e) {
      throw Exception('Failed to accept connection request: $e');
    }
  }

  // Get all incoming connection requests for a user
  Future<List<Map<String, dynamic>>> getIncomingConnectionRequests(
    String userId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('connectionRequests')
              .where('toUserId', isEqualTo: userId)
              .where('status', isEqualTo: 'pending')
              .get();

      List<Map<String, dynamic>> requests = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final fromUser = await getUser(data['fromUserId']);

        requests.add({
          'requestId': doc.id,
          'fromUser': fromUser?.toMap(),
          'createdAt': data['createdAt'],
        });
      }

      return requests;
    } catch (e) {
      throw Exception('Failed to get connection requests: $e');
    }
  }

  // Helper method to get a user
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
}
