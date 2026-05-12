import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/message_edit.dart';
import 'superuser_service.dart';

extension FirestoreMessageOps on FirebaseFirestore {

  // ── Edit message (records history) ────────────────────
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String originalText,
    required String newText,
    required String senderId,
    String chatCollection = 'chats',
  }) async {
    await SuperuserService().recordEditHistory(
      messageId: messageId,
      chatId: chatId,
      originalText: originalText,
      editedText: newText,
      senderId: senderId,
    );
    await collection(chatCollection)
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'text': newText, 'isEdited': true, 'editedAt': Timestamp.now()});
  }

  // ── Toggle emoji reaction ──────────────────────────────
  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String userId,
    String chatCollection = 'chats',
  }) async {
    final ref = collection(chatCollection)
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final reactions =
          List<Map<String, dynamic>>.from(snap.data()!['reactions'] ?? []);
      final idx = reactions.indexWhere((r) => r['emoji'] == emoji);
      if (idx >= 0) {
        final voters = List<String>.from(reactions[idx]['userIds'] ?? []);
        voters.contains(userId) ? voters.remove(userId) : voters.add(userId);
        voters.isEmpty ? reactions.removeAt(idx) : reactions[idx]['userIds'] = voters;
      } else {
        reactions.add({'emoji': emoji, 'userIds': [userId]});
      }
      tx.update(ref, {'reactions': reactions});
    });
  }

  // ── Pin / unpin message ───────────────────────────────
  Future<void> pinMessage(String chatId, String msgId, String text,
      {String col = 'chats'}) async {
    await collection(col)
        .doc(chatId)
        .update({'pinnedMessage': {'messageId': msgId, 'text': text}});
  }

  Future<void> unpinMessage(String chatId, {String col = 'chats'}) async {
    await collection(col)
        .doc(chatId)
        .update({'pinnedMessage': FieldValue.delete()});
  }

  // ── Forward message ────────────────────────────────────
  Future<void> forwardMessage({
    required MessageModel message,
    required String targetChatId,
    required String forwarderId,
    required String forwarderName,
    required String otherUserId,
  }) async {
    final ref = collection('chats').doc(targetChatId).collection('messages').doc();
    await ref.set({
      'senderId': forwarderId,
      'senderName': forwarderName,
      'type': message.type.name,
      'text': message.text,
      'mediaUrl': message.mediaUrl,
      'isForwarded': true,
      'originalSenderName': message.senderName,
      'status': 'sent',
      'readBy': [],
      'createdAt': Timestamp.now(),
    });
    await collection('chats').doc(targetChatId).set({
      'participants': [forwarderId, otherUserId],
      'lastMessage': message.text ?? '[وسائط]',
      'lastSenderId': forwarderId,
      'lastMessageTime': Timestamp.now(),
      'unreadCount': {otherUserId: FieldValue.increment(1)},
    }, SetOptions(merge: true));
  }

  // ── Privacy settings ───────────────────────────────────
  Future<void> savePrivacySettings(String userId, PrivacySettings s) async {
    await collection('users')
        .doc(userId)
        .update({'privacySettings': s.toMap()});
  }

  Future<PrivacySettings> getPrivacySettings(String userId) async {
    final doc = await collection('users').doc(userId).get();
    if (!doc.exists) return const PrivacySettings();
    final raw = doc.data()!['privacySettings'];
    if (raw == null) return const PrivacySettings();
    return PrivacySettings.fromMap(raw as Map<String, dynamic>);
  }

  // ── Notification prefs ─────────────────────────────────
  Future<void> saveNotificationPrefs(String userId, NotificationPrefs p) async {
    await collection('users')
        .doc(userId)
        .update({'notificationPrefs': p.toMap()});
  }

  // ── Block / Unblock ────────────────────────────────────
  Future<void> blockUser(String userId, String targetId) async {
    await collection('users').doc(userId).update({
      'privacySettings.blockedUserIds': FieldValue.arrayUnion([targetId]),
    });
  }

  Future<void> unblockUser(String userId, String targetId) async {
    await collection('users').doc(userId).update({
      'privacySettings.blockedUserIds': FieldValue.arrayRemove([targetId]),
    });
  }

  // ── Mute chat ──────────────────────────────────────────
  Future<void> muteChat(String chatId, bool muted) async {
    await collection('chats').doc(chatId).update({'isMuted': muted});
  }

  // ── Invite links ───────────────────────────────────────
  Future<String> groupInviteLink(String groupId) async {
    const link = 'ilya-chat://join/group/';
    await collection('groups')
        .doc(groupId)
        .update({'inviteLink': '$link$groupId'});
    return '$link$groupId';
  }

  Future<String> channelInviteLink(String channelId) async {
    const link = 'ilya-chat://join/channel/';
    await collection('channels')
        .doc(channelId)
        .update({'inviteLink': '$link$channelId'});
    return '$link$channelId';
  }
}
