// lib/features/polls/poll_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/message_edit.dart';
import '../auth/providers/providers.dart';

class PollWidget extends ConsumerWidget {
  final PollModel poll;
  final String chatId;
  final String messageId;

  const PollWidget({
    super.key,
    required this.poll,
    required this.chatId,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    if (user == null) return const SizedBox();

    final totalVotes =
        poll.options.fold<int>(0, (sum, o) => sum + o.voterIds.length);
    final hasVoted =
        poll.options.any((o) => o.voterIds.contains(user.id));

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_outlined,
                  color: AppColors.neonRed, size: 16),
              const SizedBox(width: 6),
              const Text(
                'استطلاع رأي',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.neonRed,
                    fontWeight: FontWeight.w700),
              ),
              if (poll.isAnonymous) ...[
                const SizedBox(width: 6),
                const Text(
                  '• مجهول',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            poll.question,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...poll.options.map((opt) {
            final count = opt.voterIds.length;
            final pct = totalVotes > 0 ? count / totalVotes : 0.0;
            final voted = opt.voterIds.contains(user.id);

            return GestureDetector(
              onTap: hasVoted
                  ? null
                  : () => _vote(chatId, messageId, opt.id, user.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    // Progress bar
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.glassFill,
                        border: Border.all(
                          color: voted
                              ? AppColors.neonRed.withOpacity(0.5)
                              : AppColors.glassBorder,
                          width: voted ? 1.2 : 0.5,
                        ),
                      ),
                    ),
                    // Fill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      height: 42,
                      width: double.infinity * pct,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: voted
                              ? [
                                  AppColors.neonRed.withOpacity(0.3),
                                  AppColors.neonRed.withOpacity(0.15),
                                ]
                              : [
                                  AppColors.silver.withOpacity(0.08),
                                  AppColors.silver.withOpacity(0.04),
                                ],
                        ),
                      ),
                    ),
                    Fractionally(
                      widthFactor: pct,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(colors: [
                            voted
                                ? AppColors.neonRed.withOpacity(0.25)
                                : AppColors.silver.withOpacity(0.08),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    // Label
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            if (voted)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.check_circle_rounded,
                                    color: AppColors.neonRed, size: 14),
                              ),
                            Expanded(
                              child: Text(
                                opt.text,
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: voted
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: voted
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary),
                              ),
                            ),
                            if (hasVoted)
                              Text(
                                '${(pct * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: voted
                                        ? AppColors.neonRed
                                        : AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            '$totalVotes صوت${poll.expiresAt != null ? ' · ينتهي ${poll.expiresAt!.day}/${poll.expiresAt!.month}' : ''}',
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _vote(
      String chatId, String msgId, String optId, String userId) async {
    HapticFeedback.selectionClick();
    final msgRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(msgId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(msgRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final pollData = data['poll'] as Map<String, dynamic>;
      final options =
          List<Map<String, dynamic>>.from(pollData['options'] ?? []);

      for (int i = 0; i < options.length; i++) {
        final voters = List<String>.from(options[i]['voterIds'] ?? []);
        if (options[i]['id'] == optId) {
          if (!voters.contains(userId)) voters.add(userId);
        }
        options[i]['voterIds'] = voters;
      }
      pollData['options'] = options;
      tx.update(msgRef, {'poll': pollData});
    });
  }
}

class Fractionally extends StatelessWidget {
  final double widthFactor;
  final Widget child;
  const Fractionally(
      {super.key, required this.widthFactor, required this.child});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor.clamp(0.0, 1.0),
      child: child,
    );
  }
}
