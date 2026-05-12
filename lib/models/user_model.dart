// File: lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // 12-digit unique numeric ID (doc key)
  final String username; // @handle
  final String displayName;
  final String email; // internal email for Firebase Auth
  final String? avatarUrl;
  final String? bio;
  final List<ProfileLink> links;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isSuperuser;
  final bool isBanned;
  final int profileGradientIndex;
  final int profileGradientDirection; // 0=vertical, 1=diagonal, 2=radial
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.links = const [],
    this.isOnline = false,
    this.lastSeen,
    this.isSuperuser = false,
    this.isBanned = false,
    this.profileGradientIndex = 0,
    this.profileGradientDirection = 0,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'],
      bio: map['bio'],
      links: (map['links'] as List<dynamic>? ?? [])
          .map((l) => ProfileLink.fromMap(l as Map<String, dynamic>))
          .toList(),
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
      isSuperuser: map['isSuperuser'] ?? false,
      isBanned: map['isBanned'] ?? false,
      profileGradientIndex: map['profileGradientIndex'] ?? 0,
      profileGradientDirection: map['profileGradientDirection'] ?? 0,
      fcmToken: map['fcmToken'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'links': links.map((l) => l.toMap()).toList(),
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isSuperuser': isSuperuser,
      'isBanned': isBanned,
      'profileGradientIndex': profileGradientIndex,
      'profileGradientDirection': profileGradientDirection,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? username,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bio,
    List<ProfileLink>? links,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isBanned,
    int? profileGradientIndex,
    int? profileGradientDirection,
    String? fcmToken,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      links: links ?? this.links,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isSuperuser: isSuperuser,
      isBanned: isBanned ?? this.isBanned,
      profileGradientIndex:
          profileGradientIndex ?? this.profileGradientIndex,
      profileGradientDirection:
          profileGradientDirection ?? this.profileGradientDirection,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}

class ProfileLink {
  final String url;
  final String? label;
  final int colorIndex; // index into AppColors.iconLinkColors

  const ProfileLink({
    required this.url,
    this.label,
    this.colorIndex = 0,
  });

  factory ProfileLink.fromMap(Map<String, dynamic> map) {
    return ProfileLink(
      url: map['url'] ?? '',
      label: map['label'],
      colorIndex: map['colorIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'label': label,
      'colorIndex': colorIndex,
    };
  }
}

// ── Message Model ─────────────────────────────────────
enum MessageType { text, image, video, audio, file, sticker, system }
enum MessageStatus { sending, sent, delivered, read }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final int? audioDuration; // seconds
  final bool isSelfDestruct;
  final bool isDestructed;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final MessageStatus status;
  final List<String> readBy;
  final DateTime createdAt;
  final bool isDeleted;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.audioDuration,
    this.isSelfDestruct = false,
    this.isDestructed = false,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.status = MessageStatus.sent,
    this.readBy = const [],
    required this.createdAt,
    this.isDeleted = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatar: map['senderAvatar'],
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      audioDuration: map['audioDuration'],
      isSelfDestruct: map['isSelfDestruct'] ?? false,
      isDestructed: map['isDestructed'] ?? false,
      replyToId: map['replyToId'],
      replyToText: map['replyToText'],
      replyToSender: map['replyToSender'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      readBy: List<String>.from(map['readBy'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.name,
      'text': text,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'audioDuration': audioDuration,
      'isSelfDestruct': isSelfDestruct,
      'isDestructed': isDestructed,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender,
      'status': status.name,
      'readBy': readBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
    };
  }

  MessageModel copyWith({
    MessageStatus? status,
    List<String>? readBy,
    bool? isDestructed,
    bool? isDeleted,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      text: text,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      audioDuration: audioDuration,
      isSelfDestruct: isSelfDestruct,
      isDestructed: isDestructed ?? this.isDestructed,
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSender: replyToSender,
      status: status ?? this.status,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

// ── Chat Model ────────────────────────────────────────
class ChatModel {
  final String id; // chatId = sorted userIds joined by '_'
  final List<String> participants;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final bool isMuted;

  const ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageTime,
    this.unreadCount = const {},
    this.isMuted = false,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      id: docId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastSenderId: map['lastSenderId'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      isMuted: map['isMuted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'isMuted': isMuted,
    };
  }
}

// ── Group Model ───────────────────────────────────────
class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final List<String> adminIds;
  final List<String> memberIds;
  final List<String> bannedIds;
  final Map<String, MemberRank> memberRanks;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final bool isPublic;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    this.adminIds = const [],
    this.memberIds = const [],
    this.bannedIds = const [],
    this.memberRanks = const {},
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    this.isPublic = true,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String docId) {
    return GroupModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'],
      avatarUrl: map['avatarUrl'],
      ownerId: map['ownerId'] ?? '',
      adminIds: List<String>.from(map['adminIds'] ?? []),
      memberIds: List<String>.from(map['memberIds'] ?? []),
      bannedIds: List<String>.from(map['bannedIds'] ?? []),
      memberRanks: (map['memberRanks'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, MemberRank.fromMap(v as Map<String, dynamic>)),
      ),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isPublic: map['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'bannedIds': bannedIds,
      'memberRanks': memberRanks.map((k, v) => MapEntry(k, v.toMap())),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublic': isPublic,
    };
  }
}

class MemberRank {
  final String title;
  final int colorIndex; // index into AppColors.rankColors
  final int level; // 0=owner,1=admin,2=mod,3=member,4=guest

  const MemberRank({
    required this.title,
    required this.colorIndex,
    required this.level,
  });

  factory MemberRank.fromMap(Map<String, dynamic> map) {
    return MemberRank(
      title: map['title'] ?? 'عضو',
      colorIndex: map['colorIndex'] ?? 3,
      level: map['level'] ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'colorIndex': colorIndex, 'level': level};
  }
}

// ── Channel Model ─────────────────────────────────────
class ChannelModel {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final List<String> adminIds;
  final List<String> subscriberIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final bool isOfficial; // ILYA-Chat official channel

  const ChannelModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    this.adminIds = const [],
    this.subscriberIds = const [],
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    this.isOfficial = false,
  });

  factory ChannelModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChannelModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'],
      avatarUrl: map['avatarUrl'],
      ownerId: map['ownerId'] ?? '',
      adminIds: List<String>.from(map['adminIds'] ?? []),
      subscriberIds: List<String>.from(map['subscriberIds'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isOfficial: map['isOfficial'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'subscriberIds': subscriberIds,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOfficial': isOfficial,
    };
  }
}

// ── Story Model ───────────────────────────────────────
class StoryModel {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userAvatar;
  final String mediaUrl;
  final bool isVideo;
  final String? caption;
  final List<String> viewedBy;
  final DateTime createdAt;
  final DateTime expiresAt; // +24h from createdAt

  const StoryModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    this.userAvatar,
    required this.mediaUrl,
    this.isVideo = false,
    this.caption,
    this.viewedBy = const [],
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory StoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return StoryModel(
      id: docId,
      userId: map['userId'] ?? '',
      userDisplayName: map['userDisplayName'] ?? '',
      userAvatar: map['userAvatar'],
      mediaUrl: map['mediaUrl'] ?? '',
      isVideo: map['isVideo'] ?? false,
      caption: map['caption'],
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userAvatar': userAvatar,
      'mediaUrl': mediaUrl,
      'isVideo': isVideo,
      'caption': caption,
      'viewedBy': viewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}

// ── Support Ticket Model ──────────────────────────────
class SupportTicket {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedId;
  final String reportedName;
  final String reason;
  final String? details;
  final bool isResolved;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedId,
    required this.reportedName,
    required this.reason,
    this.details,
    this.isResolved = false,
    required this.createdAt,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map, String docId) {
    return SupportTicket(
      id: docId,
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reportedId: map['reportedId'] ?? '',
      reportedName: map['reportedName'] ?? '',
      reason: map['reason'] ?? '',
      details: map['details'],
      isResolved: map['isResolved'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedId': reportedId,
      'reportedName': reportedName,
      'reason': reason,
      'details': details,
      'isResolved': isResolved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
