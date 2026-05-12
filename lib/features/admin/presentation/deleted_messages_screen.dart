// File: lib/features/admin/presentation/deleted_messages_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../models/message_edit.dart';
import '../../../services/superuser_service.dart';

final _deletedMsgsProvider =
    StreamProvider<List<DeletedMessage>>((ref) {
  return SuperuserService().streamDeletedMessages(limit: 200);
});

final _editHistoryProvider =
    StreamProvider<List<MessageEdit>>((ref) {
  return SuperuserService().streamEditHistory(limit: 200);
});

class DeletedMessagesScreen extends ConsumerStatefulWidget {
  const DeletedMessagesScreen({super.key});

  @override
  ConsumerState<DeletedMessagesScreen> createState() =>
      _DeletedMessagesScreenState();
}

class _DeletedMessagesScreenState
    extends ConsumerState<DeletedMessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          _buildSearch(),
          _buildTabs(),
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
          const NeonText(
            text: 'أرشيف الرسائل المحذوفة',
            fontSize: 16,
            glowRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: 14,
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.silverDim, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'بحث بالنص أو الـ ID...',
                  hintStyle: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _filter = v.toLowerCase()),
              ),
            ),
          ],
        ),
      ),
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
            Tab(text: 'رسائل محذوفة'),
            Tab(text: 'سجل التعديلات'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _DeletedTab(filter: _filter),
        _EditHistoryTab(filter: _filter),
      ],
    );
  }
}

// ── Deleted Messages Tab ──────────────────────────────
class _DeletedTab extends ConsumerWidget {
  final String filter;
  const _DeletedTab({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_deletedMsgsProvider);
    return async.when(
      data: (msgs) {
        final filtered = filter.isEmpty
            ? msgs
            : msgs.where((m) {
                return (m.text?.toLowerCase().contains(filter) ?? false) ||
                    m.senderId.contains(filter) ||
                    m.senderName.toLowerCase().contains(filter);
              }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد رسائل محذوفة',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _DeletedMsgCard(msg: filtered[i]),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonRed)),
      error: (e, _) =>
          Center(child: Text(e.toString(), style: const TextStyle(color: AppColors.neonRed))),
    );
  }
}

class _DeletedMsgCard extends StatelessWidget {
  final DeletedMessage msg;
  const _DeletedMsgCard({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: 14,
        borderColor: AppColors.neonRed.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.neonRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.neonRed.withOpacity(0.3)),
                  ),
                  child: Text(
                    msg.deletedForAll ? 'محذوف للجميع' : 'محذوف للمرسل',
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: AppColors.neonRed),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.glassFill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    msg.chatType,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9,
                        color: AppColors.textMuted),
                  ),
                ),
                const Spacer(),
                Text(
                  _fmt(msg.deletedAt),
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Sender
            Row(
              children: [
                const Icon(Icons.person_outline,
                    color: AppColors.silver, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${msg.senderName} (${msg.senderId})',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.silver,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Original content
            if (msg.text != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(
                  msg.text!,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textPrimary),
                ),
              ),
            if (msg.mediaUrl != null)
              Row(
                children: [
                  Icon(
                    msg.messageType == 'image'
                        ? Icons.image_outlined
                        : msg.messageType == 'audio'
                            ? Icons.mic_outlined
                            : Icons.insert_drive_file_outlined,
                    color: AppColors.silverDim,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg.messageType,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Text(
              'أُرسل في: ${_fmt(msg.originalCreatedAt)} | مسح بواسطة: ${msg.deletedBy}',
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

  String _fmt(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}

// ── Edit History Tab ──────────────────────────────────
class _EditHistoryTab extends ConsumerWidget {
  final String filter;
  const _EditHistoryTab({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_editHistoryProvider);
    return async.when(
      data: (edits) {
        final filtered = filter.isEmpty
            ? edits
            : edits.where((e) {
                return e.originalText.toLowerCase().contains(filter) ||
                    e.editedText.toLowerCase().contains(filter) ||
                    e.senderId.contains(filter);
              }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد سجل تعديلات',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _EditCard(edit: filtered[i]),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonRed)),
      error: (e, _) =>
          Center(child: Text(e.toString())),
    );
  }
}

class _EditCard extends StatelessWidget {
  final MessageEdit edit;
  const _EditCard({required this.edit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: 14,
        borderColor: AppColors.silver.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_outlined,
                    color: AppColors.silver, size: 14),
                const SizedBox(width: 6),
                Text(
                  'مُعدَّل في: ${_fmt(edit.editedAt)}',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  'ID: ${edit.senderId}',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
                      color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Before
            _diffRow('قبل التعديل', edit.originalText, AppColors.neonRed),
            const SizedBox(height: 6),
            // After
            _diffRow('بعد التعديل', edit.editedText, AppColors.online),
          ],
        ),
      ),
    );
  }

  Widget _diffRow(String label, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Text(
            text,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}
