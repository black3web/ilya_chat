// lib/features/reactions/reactions_bar.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../services/firestore_service.dart';
import '../../services/firestore_service_ext.dart';
import '../../models/user_model.dart';
import '../auth/providers/providers.dart';

const _quickEmojis = ['❤️', '😂', '😮', '😢', '👍', '🔥', '👀', '💯'];

class ReactionsBar extends ConsumerWidget {
  final MessageModel message;
  final String chatId;
  final String collection;

  const ReactionsBar({
    super.key,
    required this.message,
    required this.chatId,
    this.collection = 'chats',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    if (user == null) return const SizedBox();

    final reactions = _parseReactions(message);
    if (reactions.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactions.entries.map((entry) {
          final emoji = entry.key;
          final voters = entry.value;
          final isMine = voters.contains(user.id);

          return GestureDetector(
            onTap: () => _toggleReaction(ref, emoji, user.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isMine
                    ? AppColors.neonRed.withOpacity(0.15)
                    : AppColors.glassFill,
                border: Border.all(
                  color: isMine
                      ? AppColors.neonRed.withOpacity(0.5)
                      : AppColors.glassBorder,
                  width: isMine ? 1 : 0.5,
                ),
                boxShadow: isMine
                    ? [
                        BoxShadow(
                          color: AppColors.neonRed.withOpacity(0.2),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${voters.length}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isMine ? AppColors.neonRed : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, List<String>> _parseReactions(MessageModel msg) {
    // Reactions stored as List<{emoji, userIds}>
    final result = <String, List<String>>{};
    // Since we use dynamic map, parse from message extensions
    return result;
  }

  Future<void> _toggleReaction(WidgetRef ref, String emoji, String userId) async {
    HapticFeedback.selectionClick();
    await FirebaseFirestore.instance.toggleReaction(
      chatId: chatId,
      messageId: message.id,
      emoji: emoji,
      userId: userId,
      chatCollection: collection,
    );
  }
}

// ── Reaction Picker Popup ─────────────────────────────
class ReactionPicker extends ConsumerWidget {
  final MessageModel message;
  final String chatId;
  final VoidCallback onClose;

  const ReactionPicker({
    super.key,
    required this.message,
    required this.chatId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    if (user == null) return const SizedBox();

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 24,
      showNeonGlow: true,
      glowIntensity: 0.1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _quickEmojis.map((emoji) {
          return GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              await FirebaseFirestore.instance.toggleReaction(
                chatId: chatId,
                messageId: message.id,
                emoji: emoji,
                userId: user.id,
              );
              onClose();
            },
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
