// lib/features/search/global_search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_widgets.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../auth/providers/providers.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _searchResultsProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  return ref.read(firestoreServiceProvider).searchUsers(query);
});

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() =>
      _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  late TabController _tabCtrl;
  final _recentSearches = <String>[];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(_searchQueryProvider.notifier).state = q;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSearchBar(),
          if (query.isNotEmpty) _buildFilterTabs(),
          Expanded(
            child: query.isEmpty
                ? _buildRecentSearches()
                : _buildResults(query),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
            Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.silver, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderColor: AppColors.neonRed.withOpacity(0.3),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.neonRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: _onSearch,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'ابحث بالاسم، @يوزر، أو ID...',
                        hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        ref.read(_searchQueryProvider.notifier).state = '';
                      },
                      child: const Icon(Icons.close,
                          color: AppColors.silverDim, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassContainer(
        borderRadius: 12,
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.silverDim,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
                colors: [AppColors.neonRed, AppColors.darkRed]),
          ),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'مستخدمون'),
            Tab(text: 'مجموعات'),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(String query) {
    final resultsAsync = ref.watch(_searchResultsProvider(query));
    return resultsAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: 12),
                Text(
                  'لا نتائج لـ "$query"',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (ctx, i) => _UserSearchTile(user: users[i]),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AppColors.neonRed, strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: const TextStyle(
                color: AppColors.neonRed, fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'بحث سريع',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.neonRed),
          ),
        ),
        _QuickSearchChips(onTap: (q) {
          _ctrl.text = q;
          _onSearch(q);
        }),
      ],
    );
  }
}

class _UserSearchTile extends ConsumerWidget {
  final UserModel user;
  const _UserSearchTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (user.id == currentUser?.id) {
          context.push('/profile/${user.id}');
        } else {
          final fs = ref.read(firestoreServiceProvider);
          final chatId = fs.chatId(currentUser!.id, user.id);
          context.push('/chat/$chatId', extra: {
            'otherUserId': user.id,
            'otherUserName': user.displayName,
            'otherUserAvatar': user.avatarUrl,
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: user.isSuperuser
                      ? AppColors.neonRed.withOpacity(0.6)
                      : AppColors.glassBorder,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: user.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.surfaceLight,
                        child: Center(
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.silver),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (user.isSuperuser) ...[
                        const CrownBadge(size: 14),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        user.displayName,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      if (user.isOnline) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.online,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.neonRed),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppColors.silver, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSearchChips extends StatelessWidget {
  final void Function(String) onTap;
  const _QuickSearchChips({required this.onTap});

  static const _suggestions = [
    'a1', 'المبرمج', 'ILYA', 'admin',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions
            .map((s) => GestureDetector(
                  onTap: () => onTap(s),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    borderRadius: 20,
                    child: Text(
                      s,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
