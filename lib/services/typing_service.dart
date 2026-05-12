// File: lib/services/typing_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class TypingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _typingTimer;
  String? _currentChatId;
  String? _currentUserId;

  /// Call on every keystroke
  Future<void> setTyping(String chatId, String userId) async {
    _currentChatId = chatId;
    _currentUserId = userId;

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId)
        .set({
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Auto-clear after 3 seconds of inactivity
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      clearTyping(chatId, userId);
    });
  }

  Future<void> clearTyping(String chatId, String userId) async {
    _typingTimer?.cancel();
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .delete();
    } catch (_) {}
  }

  /// Stream of user IDs currently typing in a chat
  Stream<List<String>> streamTypingUsers(String chatId, String currentUserId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.id != currentUserId)
            .where((d) {
              final ts = d.data()['timestamp'] as Timestamp?;
              if (ts == null) return false;
              return DateTime.now().difference(ts.toDate()).inSeconds < 5;
            })
            .map((d) => d.id)
            .toList());
  }

  /// Group typing indicator
  Future<void> setGroupTyping(String groupId, String userId) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('typing')
        .doc(userId)
        .set({
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      clearGroupTyping(groupId, userId);
    });
  }

  Future<void> clearGroupTyping(String groupId, String userId) async {
    _typingTimer?.cancel();
    try {
      await _db
          .collection('groups')
          .doc(groupId)
          .collection('typing')
          .doc(userId)
          .delete();
    } catch (_) {}
  }

  Stream<List<String>> streamGroupTypingUsers(
      String groupId, String currentUserId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('typing')
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.id != currentUserId)
            .map((d) => d.id)
            .toList());
  }

  void dispose() {
    _typingTimer?.cancel();
    if (_currentChatId != null && _currentUserId != null) {
      clearTyping(_currentChatId!, _currentUserId!);
    }
  }
}
