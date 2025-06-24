import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stridemind/services/firebase_auth_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = FirebaseAuthService();

  Future<void> addConversationTurn(
      Map<String, dynamic> turn, int timestamp) async {
    final uid = _authService.uid;
    if (uid == null) {
      print("FirestoreService Error: User not logged in.");
      return;
    }

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('conversation_history')
          .add({...turn, 'timestamp': timestamp});
    } catch (e) {
      print("Error saving conversation to Firestore: $e");
    }
  }
}