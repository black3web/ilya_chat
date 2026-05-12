// File: lib/models/message_edit.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Stores the edit history for a message (superuser can view)
class MessageEdit {
  final String id;
  final String messageId;
  final String chatId;
  final String originalText;
  final String editedText;
  final String senderId;
  final DateTime editedAt;

  const MessageEdit({
    required this.id,
    required this.messageId,
    required this.chatId,
    required this.originalText,
    required this.editedText,
    required this.senderId,
    required this.editedAt,
  });

  factory MessageEdit.fromMap(Map<String, dynamic> map, String docId) {
    return MessageEdit(
      id: docId,
      messageId: map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      originalText: map['originalText'] ?? '',
      editedText: map['editedText'] ?? '',
      senderId: map['senderId'] ?? '',
      editedAt: map['editedAt'] != null
          ? (map['editedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'chatId': chatId,
        'originalText': originalText,
        'editedText': editedText,
        'senderId': senderId,
        'editedAt': Timestamp.fromDate(editedAt),
      };
}

/// Permanently deleted messages archive (superuser only)
class DeletedMessage {
  final String id;
  final String originalMessageId;
  final String chatId;
  final String chatType; // 'direct', 'group', 'channel'
  final String senderId;
  final String senderName;
  final String? text;
  final String? mediaUrl;
  final String messageType;
  final DateTime originalCreatedAt;
  final DateTime deletedAt;
  final String deletedBy;
  final bool deletedForAll;

  const DeletedMessage({
    required this.id,
    required this.originalMessageId,
    required this.chatId,
    required this.chatType,
    required this.senderId,
    required this.senderName,
    this.text,
    this.mediaUrl,
    required this.messageType,
    required this.originalCreatedAt,
    required this.deletedAt,
    required this.deletedBy,
    required this.deletedForAll,
  });

  factory DeletedMessage.fromMap(Map<String, dynamic> map, String docId) {
    return DeletedMessage(
      id: docId,
      originalMessageId: map['originalMessageId'] ?? '',
      chatId: map['chatId'] ?? '',
      chatType: map['chatType'] ?? 'direct',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      messageType: map['messageType'] ?? 'text',
      originalCreatedAt: map['originalCreatedAt'] != null
          ? (map['originalCreatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? (map['deletedAt'] as Timestamp).toDate()
          : DateTime.now(),
      deletedBy: map['deletedBy'] ?? '',
      deletedForAll: map['deletedForAll'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'originalMessageId': originalMessageId,
        'chatId': chatId,
        'chatType': chatType,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'mediaUrl': mediaUrl,
        'messageType': messageType,
        'originalCreatedAt': Timestamp.fromDate(originalCreatedAt),
        'deletedAt': Timestamp.fromDate(deletedAt),
        'deletedBy': deletedBy,
        'deletedForAll': deletedForAll,
      };
}

/// App settings / config model
class AppConfig {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final int minAppVersion;
  final String updateUrl;
  final List<String> bannedWords;
  final int maxMessageLength;
  final int maxGroupMembers;
  final int maxChannelSubscribers;
  final bool allowStickers;
  final bool allowVoiceMessages;

  const AppConfig({
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
    this.minAppVersion = 1,
    this.updateUrl = '',
    this.bannedWords = const [],
    this.maxMessageLength = 4096,
    this.maxGroupMembers = 5000,
    this.maxChannelSubscribers = 1000000,
    this.allowStickers = true,
    this.allowVoiceMessages = true,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      maintenanceMode: map['maintenanceMode'] ?? false,
      maintenanceMessage: map['maintenanceMessage'] ?? '',
      minAppVersion: map['minAppVersion'] ?? 1,
      updateUrl: map['updateUrl'] ?? '',
      bannedWords: List<String>.from(map['bannedWords'] ?? []),
      maxMessageLength: map['maxMessageLength'] ?? 4096,
      maxGroupMembers: map['maxGroupMembers'] ?? 5000,
      maxChannelSubscribers: map['maxChannelSubscribers'] ?? 1000000,
      allowStickers: map['allowStickers'] ?? true,
      allowVoiceMessages: map['allowVoiceMessages'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'maintenanceMode': maintenanceMode,
        'maintenanceMessage': maintenanceMessage,
        'minAppVersion': minAppVersion,
        'updateUrl': updateUrl,
        'bannedWords': bannedWords,
        'maxMessageLength': maxMessageLength,
        'maxGroupMembers': maxGroupMembers,
        'maxChannelSubscribers': maxChannelSubscribers,
        'allowStickers': allowStickers,
        'allowVoiceMessages': allowVoiceMessages,
      };
}

/// Poll model
class PollModel {
  final String id;
  final String question;
  final List<PollOption> options;
  final bool isMultiChoice;
  final bool isAnonymous;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const PollModel({
    required this.id,
    required this.question,
    required this.options,
    this.isMultiChoice = false,
    this.isAnonymous = false,
    this.expiresAt,
    required this.createdAt,
  });

  factory PollModel.fromMap(Map<String, dynamic> map, String docId) {
    return PollModel(
      id: docId,
      question: map['question'] ?? '',
      options: (map['options'] as List<dynamic>? ?? [])
          .map((o) => PollOption.fromMap(o as Map<String, dynamic>))
          .toList(),
      isMultiChoice: map['isMultiChoice'] ?? false,
      isAnonymous: map['isAnonymous'] ?? false,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'question': question,
        'options': options.map((o) => o.toMap()).toList(),
        'isMultiChoice': isMultiChoice,
        'isAnonymous': isAnonymous,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class PollOption {
  final String id;
  final String text;
  final List<String> voterIds;

  const PollOption({
    required this.id,
    required this.text,
    this.voterIds = const [],
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      voterIds: List<String>.from(map['voterIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'voterIds': voterIds,
      };
}

/// Message Reaction model
class MessageReaction {
  final String emoji;
  final List<String> userIds;

  const MessageReaction({
    required this.emoji,
    required this.userIds,
  });

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      emoji: map['emoji'] ?? '',
      userIds: List<String>.from(map['userIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'emoji': emoji,
        'userIds': userIds,
      };
}

/// Scheduled Message
class ScheduledMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime scheduledAt;
  final bool sent;

  const ScheduledMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.scheduledAt,
    this.sent = false,
  });

  factory ScheduledMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ScheduledMessage(
      id: docId,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      scheduledAt: map['scheduledAt'] != null
          ? (map['scheduledAt'] as Timestamp).toDate()
          : DateTime.now(),
      sent: map['sent'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'text': text,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'sent': sent,
      };
}

/// App Statistics
class AppStats {
  final int totalUsers;
  final int activeToday;
  final int totalMessages;
  final int totalGroups;
  final int totalChannels;
  final int storiesPosted;
  final int openTickets;
  final Map<String, int> messagesPerDay;

  const AppStats({
    this.totalUsers = 0,
    this.activeToday = 0,
    this.totalMessages = 0,
    this.totalGroups = 0,
    this.totalChannels = 0,
    this.storiesPosted = 0,
    this.openTickets = 0,
    this.messagesPerDay = const {},
  });
}

/// Notification Preference
class NotificationPrefs {
  final bool enableAll;
  final bool enableDirectMessages;
  final bool enableGroups;
  final bool enableChannels;
  final bool enableStories;
  final bool enableSound;
  final bool enableVibration;
  final bool enablePreview;
  final String? customSound;

  const NotificationPrefs({
    this.enableAll = true,
    this.enableDirectMessages = true,
    this.enableGroups = true,
    this.enableChannels = true,
    this.enableStories = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.enablePreview = true,
    this.customSound,
  });

  factory NotificationPrefs.fromMap(Map<String, dynamic> map) {
    return NotificationPrefs(
      enableAll: map['enableAll'] ?? true,
      enableDirectMessages: map['enableDirectMessages'] ?? true,
      enableGroups: map['enableGroups'] ?? true,
      enableChannels: map['enableChannels'] ?? true,
      enableStories: map['enableStories'] ?? true,
      enableSound: map['enableSound'] ?? true,
      enableVibration: map['enableVibration'] ?? true,
      enablePreview: map['enablePreview'] ?? true,
      customSound: map['customSound'],
    );
  }

  Map<String, dynamic> toMap() => {
        'enableAll': enableAll,
        'enableDirectMessages': enableDirectMessages,
        'enableGroups': enableGroups,
        'enableChannels': enableChannels,
        'enableStories': enableStories,
        'enableSound': enableSound,
        'enableVibration': enableVibration,
        'enablePreview': enablePreview,
        'customSound': customSound,
      };
}

/// Privacy Settings
class PrivacySettings {
  final String lastSeenVisibility; // 'everyone','contacts','nobody'
  final String profilePhotoVisibility;
  final String onlineStatusVisibility;
  final bool allowMessageFromAnyone;
  final bool allowGroupInvite;
  final bool readReceipts;
  final List<String> blockedUserIds;

  const PrivacySettings({
    this.lastSeenVisibility = 'everyone',
    this.profilePhotoVisibility = 'everyone',
    this.onlineStatusVisibility = 'everyone',
    this.allowMessageFromAnyone = true,
    this.allowGroupInvite = true,
    this.readReceipts = true,
    this.blockedUserIds = const [],
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      lastSeenVisibility: map['lastSeenVisibility'] ?? 'everyone',
      profilePhotoVisibility: map['profilePhotoVisibility'] ?? 'everyone',
      onlineStatusVisibility: map['onlineStatusVisibility'] ?? 'everyone',
      allowMessageFromAnyone: map['allowMessageFromAnyone'] ?? true,
      allowGroupInvite: map['allowGroupInvite'] ?? true,
      readReceipts: map['readReceipts'] ?? true,
      blockedUserIds: List<String>.from(map['blockedUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'lastSeenVisibility': lastSeenVisibility,
        'profilePhotoVisibility': profilePhotoVisibility,
        'onlineStatusVisibility': onlineStatusVisibility,
        'allowMessageFromAnyone': allowMessageFromAnyone,
        'allowGroupInvite': allowGroupInvite,
        'readReceipts': readReceipts,
        'blockedUserIds': blockedUserIds,
      };
}
