// File: lib/features/admin/presentation/admin_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/providers.dart';

class AdminPanel extends ConsumerStatefulWidget {
  const AdminPanel({super.key});

  @override
  ConsumerState<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends ConsumerState<AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isSuperuser) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('غير مصرح',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.neonRed,
                  fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          _buildStats(),
          _buildTabBar(),
          Expanded(child: _buildTabViews()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
            bottom: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.silver, size: 20),
          ),
          const SizedBox(width: 12),
          const CrownBadge(size: 20),
          const SizedBox(width: 8),
          const NeonText(
            text: AppStrings.adminPanel,
            fontSize: 18,
            glowRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final statsAsync = ref.watch(adminStatsProvider);
    return statsAsync.when(
      data: (stats) => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _StatCard(
                label: AppStrings.totalUsers,
                value: '${stats['totalUsers'] ?? 0}',
                icon: Icons.people_rounded,
                color: AppColors.neonRed),
            const SizedBox(width: 8),
            _StatCard(
                label: 'المجموعات',
                value: '${stats['totalGroups'] ?? 0}',
                icon: Icons.group_rounded,
                color: AppColors.silver),
            const SizedBox(width: 8),
            _StatCard(
                label: 'البلاغات',
                value: '${stats['openTickets'] ?? 0}',
                icon: Icons.flag_rounded,
                color: AppColors.neonRed),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GlassContainer(
        borderRadius: 12,
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.silverDim,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
                colors: [AppColors.neonRed, AppColors.darkRed]),
          ),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'المستخدمون'),
            Tab(text: 'المجموعات'),
            Tab(text: AppStrings.supportTickets),
          ],
        ),
      ),
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _UsersTab(),
        _GroupsAdminTab(),
        _TicketsTab(),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        borderRadius: 14,
        showNeonGlow: color == AppColors.neonRed,
        glowIntensity: 0.08,
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Users Tab ─────────────────────────────────────────
class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    return usersAsync.when(
      data: (users) => ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: users.length,
        itemBuilder: (ctx, i) => _UserAdminTile(user: users[i]),
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonRed)),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}

class _UserAdminTile extends ConsumerWidget {
  final UserModel user;
  const _UserAdminTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 14,
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: user.isBanned
                      ? AppColors.neonRed
                      : AppColors.glassBorder,
                  width: 1.2,
                ),
              ),
              child: ClipOval(
                child: user.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surfaceLight,
                        child: Center(
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.silver),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (user.isSuperuser) ...[
                        const CrownBadge(size: 12),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isBanned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neonRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'محظور',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9,
                                color: AppColors.neonRed),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '@${user.username} • ID: ${user.id}',
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            PopupMenuButton<String>(
              color: AppColors.surface,
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.silverDim, size: 18),
              onSelected: (action) async {
                switch (action) {
                  case 'ban':
                    await ref
                        .read(firestoreServiceProvider)
                        .banUser(user.id, !user.isBanned);
                    break;
                  case 'delete':
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('حذف الحساب',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.textPrimary)),
                        content: Text(
                            'هل تريد حذف حساب ${user.displayName}؟',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('إلغاء',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppColors.silverDim)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('حذف',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppColors.neonRed)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(firestoreServiceProvider)
                          .deleteUserAccount(user.id);
                    }
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'ban',
                  child: Text(
                    user.isBanned ? 'رفع الحظر' : AppStrings.ban,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textPrimary),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    AppStrings.deleteUser,
                    style: TextStyle(
                        fontFamily: 'Cairo', color: AppColors.neonRed),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Groups Admin Tab ──────────────────────────────────
class _GroupsAdminTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text(
        'إدارة المجموعات\nقريباً',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.6),
      ),
    );
  }
}

// ── Tickets Tab ───────────────────────────────────────
class _TicketsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider);
    return ticketsAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد بلاغات',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: tickets.length,
          itemBuilder: (ctx, i) => _TicketTile(ticket: tickets[i], ref: ref),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonRed)),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final SupportTicket ticket;
  final WidgetRef ref;

  const _TicketTile({required this.ticket, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: 14,
        borderColor: ticket.isResolved
            ? AppColors.glassBorder
            : AppColors.neonRed.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: ticket.isResolved
                      ? AppColors.silverDim
                      : AppColors.neonRed,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ticket.reason,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
                if (!ticket.isResolved)
                  GestureDetector(
                    onTap: () async {
                      await ref
                          .read(firestoreServiceProvider)
                          .resolveTicket(ticket.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.online.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.online.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'حل',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.online,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
                label: 'المُبلِّغ',
                value:
                    '${ticket.reporterName} (${ticket.reporterId})'),
            _InfoRow(
                label: 'المُبلَّغ عنه',
                value:
                    '${ticket.reportedName} (${ticket.reportedId})'),
            if (ticket.details != null)
              _InfoRow(label: 'التفاصيل', value: ticket.details!),
            _InfoRow(
                label: 'التاريخ',
                value:
                    '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
