// lib/app/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/providers/providers.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/language_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/chat/presentation/chat_room_screen.dart';
import '../features/groups/presentation/group_screen.dart';
import '../features/channels/presentation/channel_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/admin/presentation/admin_panel.dart';
import '../features/superuser/superuser_panel.dart';
import '../features/search/global_search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/folders/folders_screen.dart';
import '../features/calls/call_screen.dart';
import '../features/admin/presentation/deleted_messages_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = currentUser != null;
      final isAuth = ['/login', '/register', '/language', '/splash']
          .contains(state.matchedLocation);
      if (!isLoggedIn && !isAuth) return '/splash';
      if (isLoggedIn && isAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/language', builder: (_, __) => const LanguageScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/search', builder: (_, __) => const GlobalSearchScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/folders', builder: (_, __) => const FoldersScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminPanel()),
      GoRoute(path: '/superuser', builder: (_, __) => const SuperuserPanel()),
      GoRoute(path: '/deleted-messages', builder: (_, __) => const DeletedMessagesScreen()),
      GoRoute(
        path: '/chat/:chatId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ChatRoomScreen(
            chatId: state.pathParameters['chatId']!,
            otherUserId: extra['otherUserId'] ?? '',
            otherUserName: extra['otherUserName'] ?? '',
            otherUserAvatar: extra['otherUserAvatar'],
          );
        },
      ),
      GoRoute(
        path: '/group/:groupId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return GroupScreen(
            groupId: state.pathParameters['groupId']!,
            groupName: extra['groupName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/channel/:channelId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ChannelScreen(
            channelId: state.pathParameters['channelId']!,
            channelName: extra['channelName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (_, state) =>
            ProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/call',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CallScreen(
            otherUserName: extra['name'] ?? '',
            otherUserAvatar: extra['avatar'],
            callType: extra['video'] == true ? CallType.video : CallType.voice,
            isIncoming: extra['incoming'] ?? false,
          );
        },
      ),
    ],
    errorBuilder: (_, __) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: const Center(
        child: Text('الصفحة غير موجودة',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
      ),
    ),
  );
});
