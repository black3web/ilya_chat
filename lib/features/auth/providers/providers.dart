// File: lib/features/auth/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';

// ── Service Providers ─────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

// ── Shared Preferences ────────────────────────────────
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ── Current User ──────────────────────────────────────
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>(
  (ref) => CurrentUserNotifier(ref.read(authServiceProvider)),
);

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  CurrentUserNotifier(this._authService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final user = await _authService.getCurrentUser();
    state = user;
  }

  Future<bool> login({
    required String idOrUsername,
    required String password,
  }) async {
    try {
      UserModel user;
      // Check if it's a numeric ID or '1' (superuser shorthand)
      final stripped = idOrUsername.replaceAll('-', '').trim();
      if (RegExp(r'^\d+$').hasMatch(stripped)) {
        // Login with ID
        final paddedId = stripped.padLeft(12, '0');
        user = await _authService.loginWithId(
          customId: paddedId,
          password: password,
        );
      } else {
        // Login with username
        user = await _authService.loginWithUsername(
          username: idOrUsername,
          password: password,
        );
      }
      state = user;
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> register({
    required String displayName,
    required String username,
    required String password,
  }) async {
    try {
      final user = await _authService.register(
        displayName: displayName,
        username: username,
        password: password,
      );
      state = user;
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    if (state != null) {
      await _authService.logout(state!.id);
    }
    state = null;
  }

  void updateUser(UserModel user) {
    state = user;
  }
}

// ── Language Provider ─────────────────────────────────
final languageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('ar') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('language') ?? 'ar';
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }
}

// ── Bubble Shape Provider ─────────────────────────────
final bubbleShapeProvider =
    StateNotifierProvider<BubbleShapeNotifier, int>((ref) {
  return BubbleShapeNotifier();
});

class BubbleShapeNotifier extends StateNotifier<int> {
  BubbleShapeNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('bubbleShape') ?? 0;
  }

  Future<void> setShape(int shape) async {
    state = shape;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bubbleShape', shape);
  }
}

// ── Chats Provider ────────────────────────────────────
final chatsProvider = StreamProvider.family<List<ChatModel>, String>(
  (ref, userId) {
    return ref.read(firestoreServiceProvider).streamChats(userId);
  },
);

// ── Messages Provider (with pagination) ──────────────
final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.read(firestoreServiceProvider).streamMessages(chatId);
});

// ── Group Messages ────────────────────────────────────
final groupMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, groupId) {
  return ref.read(firestoreServiceProvider).streamGroupMessages(groupId);
});

// ── Channel Messages ──────────────────────────────────
final channelMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, channelId) {
  return ref.read(firestoreServiceProvider).streamChannelMessages(channelId);
});

// ── User Groups ───────────────────────────────────────
final userGroupsProvider =
    StreamProvider.family<List<GroupModel>, String>((ref, userId) {
  return ref.read(firestoreServiceProvider).streamUserGroups(userId);
});

// ── User Channels ─────────────────────────────────────
final userChannelsProvider =
    StreamProvider.family<List<ChannelModel>, String>((ref, userId) {
  return ref.read(firestoreServiceProvider).streamUserChannels(userId);
});

// ── Stories ───────────────────────────────────────────
final storiesProvider = StreamProvider<List<StoryModel>>((ref) {
  return ref.read(firestoreServiceProvider).streamActiveStories();
});

// ── Stream Single User ────────────────────────────────
final userStreamProvider =
    StreamProvider.family<UserModel?, String>((ref, userId) {
  return ref.read(firestoreServiceProvider).streamUser(userId);
});

// ── Admin Stats ───────────────────────────────────────
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(firestoreServiceProvider).getAdminStats();
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.read(firestoreServiceProvider).streamAllUsers();
});

final supportTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  return ref.read(firestoreServiceProvider).streamTickets();
});
