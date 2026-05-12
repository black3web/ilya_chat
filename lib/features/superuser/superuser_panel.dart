// lib/features/superuser/superuser_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_widgets.dart';
import '../../models/message_edit.dart';
import '../../models/user_model.dart';
import '../../services/superuser_service.dart';
import '../../services/firestore_service.dart';
import '../auth/providers/providers.dart';
import '../admin/presentation/deleted_messages_screen.dart';

final _superStatsProvider = FutureProvider<AppStats>((ref) async {
  return SuperuserService().getFullStats();
});

final _activityLogProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return SuperuserService().streamActivityLog(limit: 50);
});

class SuperuserPanel extends ConsumerStatefulWidget {
  const SuperuserPanel({super.key});

  @override
  ConsumerState<SuperuserPanel> createState() => _SuperuserPanelState();
}

class _SuperuserPanelState extends ConsumerState<SuperuserPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _maintenanceMode = false;
  final _broadcastCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await SuperuserService().getAppConfig();
    setState(() => _maintenanceMode = config.maintenanceMode);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _broadcastCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isSuperuser) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: NeonText(text: 'غير مصرح', fontSize: 20),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildStatsRow(),
          _buildTabs(),
          Expanded(child: _buildTabViews()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonRed.withOpacity(0.15),
            AppColors.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: const Border(
            bottom: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.silver, size: 20),
          ),
          const SizedBox(width: 10),
          const CrownBadge(size: 22),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeonText(
                text: 'لوحة المبرمج',
                fontSize: 18,
                glowRadius: 10,
              ),
              Text(
                AppStrings.superuserName,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textMuted),
              ),
            ],
          ),
          const Spacer(),
          // Maintenance toggle
          GestureDetector(
            onTap: _toggleMaintenance,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderRadius: 10,
              borderColor: _maintenanceMode
                  ? AppColors.neonRed.withOpacity(0.6)
                  : AppColors.glassBorder,
              child: Row(
                children: [
                  Icon(
                    Icons.construction_rounded,
                    color: _maintenanceMode
                        ? AppColors.neonRed
                        : AppColors.silverDim,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _maintenanceMode ? 'صيانة' : 'يعمل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _maintenanceMode
                          ? AppColors.neonRed
                          : AppColors.online,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final statsAsync = ref.watch(_superStatsProvider);
    return statsAsync.when(
      data: (stats) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _MiniStat(label: 'مستخدمون', value: '${stats.totalUsers}',
                icon: Icons.people_rounded, color: AppColors.neonRed),
            _MiniStat(label: 'نشطون', value: '${stats.activeToday}',
                icon: Icons.circle, color: AppColors.online),
            _MiniStat(label: 'مجموعات', value: '${stats.totalGroups}',
                icon: Icons.group_rounded, color: AppColors.silver),
            _MiniStat(label: 'بلاغات', value: '${stats.openTickets}',
                icon: Icons.flag_rounded, color: AppColors.neonRed),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GlassContainer(
        borderRadius: 12,
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.silverDim,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
                colors: [AppColors.neonRed, AppColors.darkRed]),
          ),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'المستخدمون'),
            Tab(text: 'محذوفة + تعديلات'),
            Tab(text: 'البلاغات'),
            Tab(text: 'إعدادات التطبيق'),
            Tab(text: 'سجل النشاط'),
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
        _DeletedTab(),
        _TicketsTab(),
        _AppConfigTab(maintenanceMode: _maintenanceMode,
            onToggle: _toggleMaintenance,
            broadcastCtrl: _broadcastCtrl,
            onBroadcast: _sendBroadcast),
        _ActivityTab(),
      ],
    );
  }

  Future<void> _toggleMaintenance() async {
    final newState = !_maintenanceMode;
    setState(() => _maintenanceMode = newState);
    await SuperuserService().setMaintenanceMode(newState,
        message: newState ? 'التطبيق في وضع الصيانة. يُرجى المحاولة لاحقاً.' : '');
  }

  Future<void> _sendBroadcast() async {
    final msg = _broadcastCtrl.text.trim();
    if (msg.isEmpty) return;
    await SuperuserService().broadcastSystemMessage(msg);
    _broadcastCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الإذاعة')),
      );
    }
  }
}

// ── Users Tab ─────────────────────────────────────────
class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    return usersAsync.when(
      data: (users) => ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 80),
        itemCount: users.length,
        itemBuilder: (ctx, i) => _SuperUserTile(user: users[i]),
      ),
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.neonRed)),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}

class _SuperUserTile extends ConsumerWidget {
  final UserModel user;
  const _SuperUserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: GlassContainer(
        padding: const EdgeInsets.all(10),
        borderRadius: 14,
        borderColor: user.isBanned
            ? AppColors.neonRed.withOpacity(0.3)
            : user.isSuperuser
                ? AppColors.superuserCrown.withOpacity(0.3)
                : AppColors.glassBorder,
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: ClipOval(
                child: Container(
                  color: AppColors.surfaceLight,
                  child: Center(
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
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
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isBanned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.neonRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('محظور',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 9,
                                  color: AppColors.neonRed)),
                        ),
                    ],
                  ),
                  Text(
                    '@${user.username} · ${user.id}',
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9,
                        color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              color: AppColors.surface,
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.silverDim, size: 16),
              onSelected: (action) =>
                  _handleAction(context, ref, action, user),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'view',
                  child: _menuItem(Icons.person_outline, 'عرض الملف', AppColors.silver),
                ),
                PopupMenuItem(
                  value: 'copy_id',
                  child: _menuItem(Icons.copy, 'نسخ ID', AppColors.silver),
                ),
                PopupMenuItem(
                  value: 'ban',
                  child: _menuItem(
                    user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                    user.isBanned ? 'رفع الحظر' : 'حظر',
                    AppColors.neonRed,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: _DeleteMenuItem(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: color == AppColors.silver
                    ? AppColors.textPrimary
                    : color)),
      ],
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action, UserModel user) async {
    switch (action) {
      case 'view':
        context.push('/profile/${user.id}');
        break;
      case 'copy_id':
        Clipboard.setData(ClipboardData(text: user.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.idCopied)),
        );
        break;
      case 'ban':
        await ref.read(firestoreServiceProvider).banUser(user.id, !user.isBanned);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('حذف الحساب',
                style: TextStyle(
                    fontFamily: 'Cairo', color: AppColors.textPrimary)),
            content: Text('حذف حساب ${user.displayName}؟ لا يمكن التراجع.',
                style: const TextStyle(
                    fontFamily: 'Cairo', color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء',
                      style: TextStyle(
                          fontFamily: 'Cairo', color: AppColors.silverDim))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('حذف نهائي',
                      style: TextStyle(
                          fontFamily: 'Cairo', color: AppColors.neonRed,
                          fontWeight: FontWeight.w700))),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(firestoreServiceProvider).deleteUserAccount(user.id);
        }
        break;
    }
  }
}

class _DeleteMenuItem extends StatelessWidget {
  const _DeleteMenuItem();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.delete_forever_rounded, color: AppColors.neonRed, size: 16),
        SizedBox(width: 10),
        Text('حذف الحساب',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.neonRed)),
      ],
    );
  }
}

// ── Deleted Messages + Edit History ──────────────────
class _DeletedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DeletedMessagesScreen()),
            ),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              showNeonGlow: true,
              glowIntensity: 0.1,
              child: const Row(
                children: [
                  Icon(Icons.delete_forever_rounded,
                      color: AppColors.neonRed, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أرشيف الرسائل المحذوفة',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'كل رسالة محذوفة محفوظة هنا للأبد',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.silverDim, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            child: const Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.silver, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سجل التعديلات',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'الأصل والتعديل لكل رسالة',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.silverDim, size: 20),
              ],
            ),
          ),
        ],
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
            child: Text('لا توجد بلاغات',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textMuted)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tickets.length,
          itemBuilder: (ctx, i) =>
              _TicketCard(ticket: tickets[i], ref: ref),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.neonRed)),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final WidgetRef ref;
  const _TicketCard({required this.ticket, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 14,
        borderColor: ticket.isResolved
            ? AppColors.glassBorder
            : AppColors.neonRed.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded,
                    color: ticket.isResolved
                        ? AppColors.silverDim
                        : AppColors.neonRed,
                    size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(ticket.reason,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                if (!ticket.isResolved)
                  GestureDetector(
                    onTap: () async {
                      await ref.read(firestoreServiceProvider).resolveTicket(ticket.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.online.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.online.withOpacity(0.4)),
                      ),
                      child: const Text('حل',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: AppColors.online,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'المُبلِّغ: ${ticket.reporterName} | المُبلَّغ: ${ticket.reportedName}',
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Config Tab ────────────────────────────────────
class _AppConfigTab extends StatelessWidget {
  final bool maintenanceMode;
  final VoidCallback onToggle;
  final TextEditingController broadcastCtrl;
  final VoidCallback onBroadcast;

  const _AppConfigTab({
    required this.maintenanceMode,
    required this.onToggle,
    required this.broadcastCtrl,
    required this.onBroadcast,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Maintenance
        GlassContainer(
          padding: const EdgeInsets.all(14),
          borderRadius: 14,
          borderColor: maintenanceMode
              ? AppColors.neonRed.withOpacity(0.4)
              : AppColors.glassBorder,
          child: Row(
            children: [
              Icon(Icons.construction_rounded,
                  color: maintenanceMode
                      ? AppColors.neonRed
                      : AppColors.silver,
                  size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('وضع الصيانة',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Switch(
                value: maintenanceMode,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.neonRed,
                activeTrackColor: AppColors.neonRed.withOpacity(0.3),
                inactiveThumbColor: AppColors.silverDim,
                inactiveTrackColor: AppColors.glassFill,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Broadcast
        const Text(
          'إذاعة عامة',
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.neonRed),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          padding: const EdgeInsets.all(12),
          borderRadius: 14,
          child: Column(
            children: [
              TextField(
                controller: broadcastCtrl,
                maxLines: 3,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة إذاعة لجميع المستخدمين...',
                  hintStyle: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onBroadcast,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                        colors: [AppColors.neonRed, AppColors.darkRed]),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'إرسال للجميع',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Activity Log Tab ──────────────────────────────────
class _ActivityTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_activityLogProvider);
    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(
            child: Text('لا يوجد نشاط',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textMuted)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: logs.length,
          itemBuilder: (ctx, i) {
            final log = logs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                borderRadius: 12,
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.neonRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log['action'] ?? ''}',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                          Text(
                            'ID: ${log['userId'] ?? ''}',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.neonRed)),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}

// ── Mini Stat Widget ──────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        borderRadius: 12,
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9,
                  color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
