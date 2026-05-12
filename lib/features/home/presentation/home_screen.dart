// File: lib/features/home/presentation/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/providers.dart';
import '../widgets/chat_list_tile.dart';
import '../widgets/story_ring.dart';
import '../widgets/glass_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _drawerOpen = false;
  late AnimationController _drawerCtrl;
  late Animation<double> _drawerAnim;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searching = false;

  final List<String> _tabs = [
    AppStrings.chats,
    AppStrings.groups,
    AppStrings.channels,
    AppStrings.folders,
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _drawerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
    _drawerAnim =
        CurvedAnimation(parent: _drawerCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _drawerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() => _drawerOpen = !_drawerOpen);
    _drawerOpen ? _drawerCtrl.forward() : _drawerCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Main Content ──────────────────────────────
          Column(
            children: [
              _buildAppBar(user),
              _buildStoriesRow(user),
              _buildTabBar(),
              Expanded(child: _buildTabViews(user)),
            ],
          ),
          // ── Drawer Overlay ────────────────────────────
          AnimatedBuilder(
            animation: _drawerAnim,
            builder: (ctx, _) {
              if (_drawerAnim.value == 0) return const SizedBox();
              return GestureDetector(
                onTap: _toggleDrawer,
                child: Container(
                  color: Colors.black.withOpacity(0.6 * _drawerAnim.value),
                ),
              );
            },
          ),
          // ── Glass Drawer ──────────────────────────────
          AnimatedBuilder(
            animation: _drawerAnim,
            builder: (ctx, child) {
              final dx = (1 - _drawerAnim.value) * -320.0;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: GlassDrawer(
              user: user,
              onClose: _toggleDrawer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(UserModel user) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          // Hamburger
          GestureDetector(
            onTap: _toggleDrawer,
            child: GlassContainer(
              padding: const EdgeInsets.all(8),
              borderRadius: 12,
              child: const AppIcon(
                  type: AppIconType.hamburger,
                  size: 20,
                  color: AppColors.silver),
            ),
          ),
          const SizedBox(width: 12),
          // Search or Title
          Expanded(
            child: _searching
                ? GlassContainer(
                    borderRadius: 14,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            color: AppColors.silverDim, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'بحث بـ ID، اسم المستخدم، الاسم...',
                              hintStyle: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  color: AppColors.textMuted),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searching = false);
                          },
                          child: const Icon(Icons.close,
                              color: AppColors.silverDim, size: 18),
                        ),
                      ],
                    ),
                  )
                : const Center(child: AppLogoText(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          // Search button
          GestureDetector(
            onTap: () => setState(() => _searching = !_searching),
            child: GlassContainer(
              padding: const EdgeInsets.all(8),
              borderRadius: 12,
              child: const AppIcon(
                  type: AppIconType.search,
                  size: 20,
                  color: AppColors.silver),
            ),
          ),
          if (user.isSuperuser) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/admin'),
              child: GlassContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: 12,
                borderColor: AppColors.neonRed.withOpacity(0.5),
                child: const CrownBadge(size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoriesRow(UserModel user) {
    final storiesAsync = ref.watch(storiesProvider);
    return SizedBox(
      height: 90,
      child: storiesAsync.when(
        data: (stories) {
          // Group stories by user
          final userStoryMap = <String, List<StoryModel>>{};
          for (final s in stories) {
            userStoryMap.putIfAbsent(s.userId, () => []).add(s);
          }
          final userIds = userStoryMap.keys.toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: userIds.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                // Add story button
                return StoryRing(
                  userId: user.id,
                  avatarUrl: user.avatarUrl,
                  name: 'قصتي',
                  stories: userStoryMap[user.id] ?? [],
                  isOwn: true,
                  currentUserId: user.id,
                );
              }
              final uid = userIds[i - 1];
              final storyList = userStoryMap[uid]!;
              return StoryRing(
                userId: uid,
                avatarUrl: storyList.first.userAvatar,
                name: storyList.first.userDisplayName,
                stories: storyList,
                isOwn: uid == user.id,
                currentUserId: user.id,
              );
            },
          );
        },
        loading: () => const SizedBox(),
        error: (e, _) => const SizedBox(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.silverDim,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w400),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [AppColors.neonRed, AppColors.darkRed],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonRed.withOpacity(0.4),
                blurRadius: 8,
              ),
            ],
          ),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: _tabs
              .map((t) => Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(t),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTabViews(UserModel user) {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _ChatsTab(user: user),
        _GroupsTab(user: user),
        _ChannelsTab(user: user),
        _FoldersTab(),
      ],
    );
  }
}

// ── Chats Tab ─────────────────────────────────────────
class _ChatsTab extends ConsumerWidget {
  final UserModel user;
  const _ChatsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider(user.id));
    return chatsAsync.when(
      data: (chats) {
        if (chats.isEmpty) {
          return _emptyState('لا توجد محادثات بعد', 'ابحث عن مستخدم لبدء المحادثة');
        }
        // Add saved messages at top
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: chats.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return ChatListTile(
                title: AppStrings.saved,
                subtitle: 'الحافظة الشخصية',
                avatarUrl: null,
                isSaved: true,
                onTap: () {
                  final chatId = '${user.id}_saved';
                  context.push('/chat/$chatId', extra: {
                    'otherUserId': user.id,
                    'otherUserName': AppStrings.saved,
                    'otherUserAvatar': null,
                  });
                },
              );
            }
            final chat = chats[i - 1];
            final otherId = chat.participants
                .firstWhere((p) => p != user.id, orElse: () => user.id);
            return _ChatTileLoader(
                chat: chat, userId: user.id, otherId: otherId);
          },
        );
      },
      loading: () => _loadingList(),
      error: (e, _) => _emptyState('خطأ في التحميل', e.toString()),
    );
  }
}

class _ChatTileLoader extends ConsumerWidget {
  final ChatModel chat;
  final String userId;
  final String otherId;
  const _ChatTileLoader(
      {required this.chat, required this.userId, required this.otherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherAsync = ref.watch(userStreamProvider(otherId));
    return otherAsync.when(
      data: (other) {
        if (other == null) return const SizedBox();
        final unread = chat.unreadCount[userId] ?? 0;
        return ChatListTile(
          title: other.displayName,
          subtitle: chat.lastMessage ?? '',
          avatarUrl: other.avatarUrl,
          unreadCount: unread,
          isOnline: other.isOnline,
          isSuperuser: other.isSuperuser,
          time: chat.lastMessageTime,
          lastSenderId: chat.lastSenderId,
          currentUserId: userId,
          onTap: () {
            context.push('/chat/${chat.id}', extra: {
              'otherUserId': other.id,
              'otherUserName': other.displayName,
              'otherUserAvatar': other.avatarUrl,
            });
          },
        );
      },
      loading: () => const SizedBox(height: 72),
      error: (_, __) => const SizedBox(),
    );
  }
}

// ── Groups Tab ────────────────────────────────────────
class _GroupsTab extends ConsumerWidget {
  final UserModel user;
  const _GroupsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider(user.id));
    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return _emptyState('لا توجد مجموعات', 'انضم أو أنشئ مجموعة جديدة');
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: groups.length,
          itemBuilder: (ctx, i) {
            final g = groups[i];
            return ChatListTile(
              title: g.name,
              subtitle: g.lastMessage ?? 'مجموعة',
              avatarUrl: g.avatarUrl,
              isGroup: true,
              time: g.lastMessageTime,
              onTap: () => context.push('/group/${g.id}',
                  extra: {'groupName': g.name}),
            );
          },
        );
      },
      loading: () => _loadingList(),
      error: (e, _) => _emptyState('خطأ', e.toString()),
    );
  }
}

// ── Channels Tab ──────────────────────────────────────
class _ChannelsTab extends ConsumerWidget {
  final UserModel user;
  const _ChannelsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(userChannelsProvider(user.id));
    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return _emptyState('لا توجد قنوات', 'اشترك في قناة');
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: channels.length,
          itemBuilder: (ctx, i) {
            final ch = channels[i];
            return ChatListTile(
              title: ch.name,
              subtitle: ch.lastMessage ?? 'قناة',
              avatarUrl: ch.avatarUrl,
              isChannel: true,
              isOfficial: ch.isOfficial,
              time: ch.lastMessageTime,
              onTap: () => context.push('/channel/${ch.id}',
                  extra: {'channelName': ch.name}),
            );
          },
        );
      },
      loading: () => _loadingList(),
      error: (e, _) => _emptyState('خطأ', e.toString()),
    );
  }
}

// ── Folders Tab ───────────────────────────────────────
class _FoldersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _emptyState('المجلدات', 'قريباً - نظام تنظيم المحادثات');
  }
}

// ── Helpers ───────────────────────────────────────────
Widget _emptyState(String title, String subtitle) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonRed.withOpacity(0.08),
            border:
                Border.all(color: AppColors.neonRed.withOpacity(0.2), width: 1),
          ),
          child: const Icon(Icons.forum_outlined,
              color: AppColors.neonRed, size: 30),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textMuted)),
      ],
    ),
  );
}

Widget _loadingList() {
  return ListView.builder(
    itemCount: 6,
    padding: const EdgeInsets.only(top: 8),
    itemBuilder: (ctx, i) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const GlassShimmer(width: 52, height: 52, borderRadius: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                GlassShimmer(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                GlassShimmer(width: 200, height: 11, borderRadius: 5),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
