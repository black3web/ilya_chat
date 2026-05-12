// File: lib/features/groups/presentation/group_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/providers.dart';
import '../../chat/widgets/message_bubble.dart';
import '../../chat/widgets/reply_preview.dart';

class GroupScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  const GroupScreen({super.key, required this.groupId, required this.groupName});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  MessageModel? _replyTo;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    _msgCtrl.clear();
    await ref.read(firestoreServiceProvider).sendGroupMessage(
      groupId: widget.groupId,
      message: MessageModel(
        id: '',
        senderId: user.id,
        senderName: user.displayName,
        senderAvatar: user.avatarUrl,
        type: MessageType.text,
        text: text,
        replyToId: _replyTo?.id,
        replyToText: _replyTo?.text,
        replyToSender: _replyTo?.senderName,
        createdAt: DateTime.now(),
      ),
      memberCount: 0,
    );
    setState(() => _replyTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();
    final msgsAsync = ref.watch(groupMessagesProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: msgsAsync.when(
              data: (msgs) => ListView.builder(
                controller: _scrollCtrl,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: msgs.length,
                itemBuilder: (ctx, i) {
                  final msg = msgs[i];
                  return MessageBubble(
                    message: msg,
                    isMe: msg.senderId == user.id,
                    bubbleShape: ref.watch(bubbleShapeProvider),
                    onReply: () => setState(() => _replyTo = msg),
                    onDelete: null,
                    onCopy: null,
                  );
                },
              ),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.neonRed)),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
          if (_replyTo != null)
            ReplyPreview(
                message: _replyTo!,
                onCancel: () => setState(() => _replyTo = null)),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 12,
        right: 12,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceLight,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.group_rounded,
                color: AppColors.silver, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const Text(
                  'مجموعة',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded,
              color: AppColors.silver, size: 22),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        border: const Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: TextField(
                controller: _msgCtrl,
                maxLines: null,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: AppStrings.typeMessage,
                  hintStyle: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [AppColors.neonRed, AppColors.darkRed]),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.neonRed.withOpacity(0.4),
                      blurRadius: 12)
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
