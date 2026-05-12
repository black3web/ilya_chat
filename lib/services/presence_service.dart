// lib/services/presence_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _customUserId;

  void init(String customUserId) {
    _customUserId = customUserId;
  }

  Future<void> setOnline() async {
    if (_customUserId == null) return;
    await _db.collection('users').doc(_customUserId).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    // Mark presence doc for auto-cleanup
    await _db.collection('presence').doc(_customUserId).set({
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'uid': _auth.currentUser?.uid ?? '',
    });
  }

  Future<void> setOffline() async {
    if (_customUserId == null) return;
    await _db.collection('users').doc(_customUserId).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    await _db.collection('presence').doc(_customUserId).update({
      'online': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>?> watchPresence(String userId) {
    return _db
        .collection('presence')
        .doc(userId)
        .snapshots()
        .map((s) => s.exists ? s.data() : null);
  }

  Future<void> updateLastSeen() async {
    if (_customUserId == null) return;
    await _db.collection('users').doc(_customUserId).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
