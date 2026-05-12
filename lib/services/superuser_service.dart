// File: lib/services/superuser_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_edit.dart';
import '../models/user_model.dart';

/// Full superuser (المبرمج إيليا) exclusive service.
/// Provides access to deleted messages, edit history, and full app control.
class SuperuserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Deleted Messages Archive ──────────────────────────
  /// Archive a message before deletion (called before any delete)
  Future<void> archiveDeletedMessage({
    required MessageModel message,
    required String chatId,
    required String chatType, // 'direct','group','channel'
    required String deletedBy,
    required bool deletedForAll,
  }) async {
    final archive = DeletedMessage(
      id: '${message.id}_${DateTime.now().millisecondsSinceEpoch}',
      originalMessageId: message.id,
      chatId: chatId,
      chatType: chatType,
      senderId: message.senderId,
      senderName: message.senderName,
      text: message.text,
      mediaUrl: message.mediaUrl,
      messageType: message.type.name,
      originalCreatedAt: message.createdAt,
      deletedAt: DateTime.now(),
      deletedBy: deletedBy,
      deletedForAll: deletedForAll,
    );
    await _db
        .collection('superuser_deleted_messages')
        .doc(archive.id)
        .set(archive.toMap());
  }

  /// Stream all deleted messages (superuser only)
  Stream<List<DeletedMessage>> streamDeletedMessages({
    String? chatId,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('superuser_deleted_messages')
        .orderBy('deletedAt', descending: true)
        .limit(limit);
    if (chatId != null) {
      q = q.where('chatId', isEqualTo: chatId);
    }
    return q.snapshots().map((snap) => snap.docs
        .map((d) => DeletedMessage.fromMap(d.data(), d.id))
        .toList());
  }

  /// Search deleted messages by sender
  Future<List<DeletedMessage>> searchDeletedMessages(String senderId) async {
    final snap = await _db
        .collection('superuser_deleted_messages')
        .where('senderId', isEqualTo: senderId)
        .orderBy('deletedAt', descending: true)
        .limit(200)
        .get();
    return snap.docs
        .map((d) => DeletedMessage.fromMap(d.data(), d.id))
        .toList();
  }

  // ── Message Edit History ──────────────────────────────
  /// Record edit history before a message is edited
  Future<void> recordEditHistory({
    required String messageId,
    required String chatId,
    required String originalText,
    required String editedText,
    required String senderId,
  }) async {
    final edit = MessageEdit(
      id: '${messageId}_${DateTime.now().millisecondsSinceEpoch}',
      messageId: messageId,
      chatId: chatId,
      originalText: originalText,
      editedText: editedText,
      senderId: senderId,
      editedAt: DateTime.now(),
    );
    await _db
        .collection('superuser_edit_history')
        .doc(edit.id)
        .set(edit.toMap());
  }

  /// Get edit history for a specific message
  Future<List<MessageEdit>> getEditHistory(String messageId) async {
    final snap = await _db
        .collection('superuser_edit_history')
        .where('messageId', isEqualTo: messageId)
        .orderBy('editedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => MessageEdit.fromMap(d.data(), d.id))
        .toList();
  }

  /// Stream all edit history (superuser dashboard)
  Stream<List<MessageEdit>> streamEditHistory({int limit = 100}) {
    return _db
        .collection('superuser_edit_history')
        .orderBy('editedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageEdit.fromMap(d.data(), d.id))
            .toList());
  }

  // ── App Config ────────────────────────────────────────
  Future<AppConfig> getAppConfig() async {
    final doc = await _db.collection('app_config').doc('main').get();
    if (!doc.exists) return const AppConfig();
    return AppConfig.fromMap(doc.data()!);
  }

  Future<void> updateAppConfig(AppConfig config) async {
    await _db
        .collection('app_config')
        .doc('main')
        .set(config.toMap(), SetOptions(merge: true));
  }

  Stream<AppConfig> streamAppConfig() {
    return _db.collection('app_config').doc('main').snapshots().map(
          (snap) =>
              snap.exists ? AppConfig.fromMap(snap.data()!) : const AppConfig(),
        );
  }

  // ── Full App Stats ────────────────────────────────────
  Future<AppStats> getFullStats() async {
    final users = await _db.collection('users').count().get();
    final groups = await _db.collection('groups').count().get();
    final channels = await _db.collection('channels').count().get();
    final tickets = await _db
        .collection('support_tickets')
        .where('isResolved', isEqualTo: false)
        .count()
        .get();
    final stories = await _db.collection('stories').count().get();

    // Active today (lastSeen within 24h)
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    final active = await _db
        .collection('users')
        .where('lastSeen', isGreaterThan: Timestamp.fromDate(yesterday))
        .count()
        .get();

    // Deleted messages count
    final deleted = await _db
        .collection('superuser_deleted_messages')
        .count()
        .get();

    return AppStats(
      totalUsers: users.count ?? 0,
      activeToday: active.count ?? 0,
      totalGroups: groups.count ?? 0,
      totalChannels: channels.count ?? 0,
      storiesPosted: stories.count ?? 0,
      openTickets: tickets.count ?? 0,
    );
  }

  // ── Broadcast System Message ──────────────────────────
  Future<void> broadcastSystemMessage(String message) async {
    await _db.collection('system_broadcasts').add({
      'message': message,
      'createdAt': Timestamp.now(),
      'isActive': true,
    });
  }

  Stream<Map<String, dynamic>?> streamActiveBroadcast() {
    return _db
        .collection('system_broadcasts')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isNotEmpty ? snap.docs.first.data() : null);
  }

  Future<void> dismissBroadcast(String broadcastId) async {
    await _db
        .collection('system_broadcasts')
        .doc(broadcastId)
        .update({'isActive': false});
  }

  // ── Force Update ──────────────────────────────────────
  Future<void> setForceUpdate({
    required int minVersion,
    required String updateUrl,
  }) async {
    await _db.collection('app_config').doc('main').set({
      'minAppVersion': minVersion,
      'updateUrl': updateUrl,
    }, SetOptions(merge: true));
  }

  // ── User Activity Log ─────────────────────────────────
  Future<void> logUserActivity({
    required String userId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    await _db.collection('superuser_activity_log').add({
      'userId': userId,
      'action': action,
      'metadata': metadata ?? {},
      'timestamp': Timestamp.now(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamActivityLog({int limit = 100}) {
    return _db
        .collection('superuser_activity_log')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── IP / Device Bans ──────────────────────────────────
  Future<void> banDevice(String deviceId, String reason) async {
    await _db.collection('banned_devices').doc(deviceId).set({
      'deviceId': deviceId,
      'reason': reason,
      'bannedAt': Timestamp.now(),
    });
  }

  Future<bool> isDeviceBanned(String deviceId) async {
    final doc =
        await _db.collection('banned_devices').doc(deviceId).get();
    return doc.exists;
  }

  // ── Message Inspector (any chat) ──────────────────────
  Stream<List<MessageModel>> inspectChat(String chatId, {int limit = 50}) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Delete any message from any chat ─────────────────
  Future<void> forceDeleteMessage({
    required String chatId,
    required String messageId,
    required MessageModel message,
    required String superuserId,
  }) async {
    // Archive first
    await archiveDeletedMessage(
      message: message,
      chatId: chatId,
      chatType: 'direct',
      deletedBy: superuserId,
      deletedForAll: true,
    );
    // Then delete permanently
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // ── Global Search ─────────────────────────────────────
  Future<List<UserModel>> searchAllUsers(String query) async {
    final lq = query.toLowerCase();
    final byUsername = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lq)
        .where('username', isLessThan: '${lq}z')
        .limit(30)
        .get();
    final byName = await _db
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: '${query}z')
        .limit(30)
        .get();

    final seen = <String>{};
    final results = <UserModel>[];
    for (final d in [...byUsername.docs, ...byName.docs]) {
      final u = UserModel.fromMap(d.data(), d.id);
      if (seen.add(u.id)) results.add(u);
    }
    return results;
  }

  // ── Maintenance Mode ──────────────────────────────────
  Future<void> setMaintenanceMode(bool enabled, {String message = ''}) async {
    await _db.collection('app_config').doc('main').set({
      'maintenanceMode': enabled,
      'maintenanceMessage': message,
    }, SetOptions(merge: true));
  }
}
