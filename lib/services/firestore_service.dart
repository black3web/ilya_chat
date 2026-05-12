// File: lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ────────────────────────────────────────────
  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<UserModel?> streamUser(String userId) {
    return _db.collection('users').doc(userId).snapshots().map(
          (snap) =>
              snap.exists ? UserModel.fromMap(snap.data()!, snap.id) : null,
        );
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final lq = query.toLowerCase();
    final results = <UserModel>[];

    // Search by username
    final byUsername = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lq)
        .where('username', isLessThan: '${lq}z')
        .limit(10)
        .get();

    // Search by displayName
    final byName = await _db
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: '${query}z')
        .limit(10)
        .get();

    // Search by ID (exact)
    UserModel? byId;
    if (RegExp(r'^\d{12}$').hasMatch(query)) {
      final doc = await _db.collection('users').doc(query).get();
      if (doc.exists) byId = UserModel.fromMap(doc.data()!, doc.id);
    }

    final seen = <String>{};
    if (byId != null && seen.add(byId.id)) results.add(byId);
    for (final d in [...byUsername.docs, ...byName.docs]) {
      final u = UserModel.fromMap(d.data(), d.id);
      if (seen.add(u.id)) results.add(u);
    }
    return results;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  // ── Chats ─────────────────────────────────────────────
  String chatId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<ChatModel>> streamChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<ChatModel> getOrCreateChat(String a, String b) async {
    final id = chatId(a, b);
    final doc = await _db.collection('chats').doc(id).get();
    if (doc.exists) return ChatModel.fromMap(doc.data()!, doc.id);

    final chat = ChatModel(
      id: id,
      participants: [a, b],
    );
    await _db.collection('chats').doc(id).set(chat.toMap());
    return chat;
  }

  // ── Messages ─────────────────────────────────────────
  Stream<List<MessageModel>> streamMessages(
    String chatId, {
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.snapshots().map((snap) => snap.docs
        .map((d) => MessageModel.fromMap(d.data(), d.id))
        .toList());
  }

  Future<MessageModel> sendMessage({
    required String chatId,
    required MessageModel message,
    required String otherUserId,
  }) async {
    final ref = _db.collection('chats').doc(chatId).collection('messages').doc();
    final msg = MessageModel(
      id: ref.id,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      type: message.type,
      text: message.text,
      mediaUrl: message.mediaUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      audioDuration: message.audioDuration,
      isSelfDestruct: message.isSelfDestruct,
      replyToId: message.replyToId,
      replyToText: message.replyToText,
      replyToSender: message.replyToSender,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );
    await ref.set(msg.toMap());

    // Update chat metadata
    await _db.collection('chats').doc(chatId).set({
      'participants': [message.senderId, otherUserId],
      'lastMessage': message.type == MessageType.text
          ? message.text
          : _typeLabel(message.type),
      'lastSenderId': message.senderId,
      'lastMessageTime': Timestamp.now(),
      'unreadCount': {otherUserId: FieldValue.increment(1)},
    }, SetOptions(merge: true));

    return msg;
  }

  String _typeLabel(MessageType t) {
    switch (t) {
      case MessageType.image:
        return 'صورة';
      case MessageType.video:
        return 'فيديو';
      case MessageType.audio:
        return 'رسالة صوتية';
      case MessageType.file:
        return 'ملف';
      case MessageType.sticker:
        return 'ملصق';
      default:
        return 'رسالة';
    }
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required bool deleteForAll,
  }) async {
    if (deleteForAll) {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true, 'text': null, 'mediaUrl': null});
    } else {
      // Soft delete for sender only - mark as deleted
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
    }
  }

  Future<void> markMessagesRead(String chatId, String userId) async {
    await _db.collection('chats').doc(chatId).update({
      'unreadCount.$userId': 0,
    });
    // Update recent messages as read
    final unread = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('status', isNotEqualTo: 'read')
        .limit(50)
        .get();
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {
        'status': 'read',
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();
  }

  Future<void> destroySelfDestructMessage(
      String chatId, String messageId) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // ── Group Messages ───────────────────────────────────
  Stream<List<MessageModel>> streamGroupMessages(String groupId,
      {int limit = 30}) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required MessageModel message,
    required int memberCount,
  }) async {
    final ref = _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc();
    final msg = MessageModel(
      id: ref.id,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      type: message.type,
      text: message.text,
      mediaUrl: message.mediaUrl,
      replyToId: message.replyToId,
      replyToText: message.replyToText,
      replyToSender: message.replyToSender,
      createdAt: DateTime.now(),
    );
    await ref.set(msg.toMap());
    await _db.collection('groups').doc(groupId).update({
      'lastMessage': message.text ?? _typeLabel(message.type),
      'lastMessageTime': Timestamp.now(),
    });
  }

  // ── Channel Messages ─────────────────────────────────
  Stream<List<MessageModel>> streamChannelMessages(String channelId,
      {int limit = 30}) {
    return _db
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> sendChannelMessage({
    required String channelId,
    required MessageModel message,
  }) async {
    final ref = _db
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc();
    await ref.set(MessageModel(
      id: ref.id,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      type: message.type,
      text: message.text,
      mediaUrl: message.mediaUrl,
      createdAt: DateTime.now(),
    ).toMap());
    await _db.collection('channels').doc(channelId).update({
      'lastMessage': message.text ?? _typeLabel(message.type),
      'lastMessageTime': Timestamp.now(),
    });
  }

  // ── Stories ───────────────────────────────────────────
  Stream<List<StoryModel>> streamActiveStories() {
    return _db
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StoryModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> addStory(StoryModel story) async {
    await _db.collection('stories').doc(story.id).set(story.toMap());
  }

  Future<void> markStoryViewed(String storyId, String userId) async {
    await _db.collection('stories').doc(storyId).update({
      'viewedBy': FieldValue.arrayUnion([userId]),
    });
  }

  // ── Groups ────────────────────────────────────────────
  Stream<List<GroupModel>> streamUserGroups(String userId) {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GroupModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<GroupModel> createGroup({
    required String name,
    required String ownerId,
    String? description,
  }) async {
    final ref = _db.collection('groups').doc();
    final group = GroupModel(
      id: ref.id,
      name: name,
      description: description,
      ownerId: ownerId,
      adminIds: [ownerId],
      memberIds: [ownerId],
      createdAt: DateTime.now(),
    );
    await ref.set(group.toMap());
    return group;
  }

  Future<void> joinGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  // ── Channels ──────────────────────────────────────────
  Stream<List<ChannelModel>> streamUserChannels(String userId) {
    return _db
        .collection('channels')
        .where('subscriberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChannelModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Admin ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final usersSnap = await _db.collection('users').count().get();
      final groupsSnap = await _db.collection('groups').count().get();
      final channelsSnap = await _db.collection('channels').count().get();
      final ticketsSnap = await _db
          .collection('support_tickets')
          .where('isResolved', isEqualTo: false)
          .count()
          .get();

      return {
        'totalUsers': usersSnap.count ?? 0,
        'totalGroups': groupsSnap.count ?? 0,
        'totalChannels': channelsSnap.count ?? 0,
        'openTickets': ticketsSnap.count ?? 0,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'totalGroups': 0,
        'totalChannels': 0,
        'openTickets': 0,
      };
    }
  }

  Stream<List<UserModel>> streamAllUsers({int limit = 50}) {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> banUser(String userId, bool ban) async {
    await _db.collection('users').doc(userId).update({'isBanned': ban});
  }

  Future<void> deleteUserAccount(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  // ── Support Tickets ───────────────────────────────────
  Future<void> submitReport(SupportTicket ticket) async {
    await _db
        .collection('support_tickets')
        .doc(ticket.id)
        .set(ticket.toMap());
  }

  Stream<List<SupportTicket>> streamTickets() {
    return _db
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportTicket.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> resolveTicket(String ticketId) async {
    await _db
        .collection('support_tickets')
        .doc(ticketId)
        .update({'isResolved': true});
  }
}
