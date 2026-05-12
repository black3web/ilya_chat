// File: lib/features/home/widgets/chat_list_tile.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/widgets/glass_container.dart';

class ChatListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? avatarUrl;
  final int unreadCount;
  final bool isOnline;
  final bool isSaved;
  final bool isGroup;
  final bool isChannel;
  final bool isOfficial;
  final bool isSuperuser;
  final DateTime? time;
  final String? lastSenderId;
  final String? currentUserId;
  final VoidCallback? onTap;

  const ChatListTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isSaved = false,
    this.isGroup = false,
    this.isChannel = false,
    this.isOfficial = false,
    this.isSuperuser = false,
    this.time,
    this.lastSenderId,
    this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: AppColors.neonRed.withOpacity(0.05),
              highlightColor: AppColors.neonRed.withOpacity(0.03),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: unreadCount > 0
                      ? AppColors.neonRedFaint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: unreadCount > 0
                      ? Border.all(
                          color: AppColors.neonRed.withOpacity(0.15), width: 0.5)
                      : null,
                ),
                child: Row(
                  children: [
                    // Avatar
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isSuperuser) ...[
                                const CrownBadge(size: 14),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isOfficial)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonRed.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.neonRed.withOpacity(0.4)),
                                  ),
                                  child: const Text(
                                    'رسمي',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 9,
                                      color: AppColors.neonRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              if (time != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(time!),
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: unreadCount > 0
                                        ? AppColors.neonRed
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Read receipts (for sent messages)
                              if (lastSenderId == currentUserId &&
                                  !isGroup &&
                                  !isChannel &&
                                  !isSaved)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: _ReadReceiptIcon(),
                                ),
                              Expanded(
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: unreadCount > 0
                                        ? AppColors.textSecondary
                                        : AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  constraints: const BoxConstraints(minWidth: 20),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonRed,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.neonRed.withOpacity(0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOnline
                  ? AppColors.online.withOpacity(0.6)
                  : AppColors.glassBorder,
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: isSaved
                ? Container(
                    color: AppColors.neonRed.withOpacity(0.12),
                    child: const Icon(Icons.bookmark_rounded,
                        color: AppColors.neonRed, size: 24),
                  )
                : isGroup
                    ? Container(
                        color: AppColors.surface,
                        child: const Icon(Icons.group_rounded,
                            color: AppColors.silver, size: 24),
                      )
                    : isChannel
                        ? Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.campaign_rounded,
                                color: AppColors.silver, size: 24),
                          )
                        : avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.surface,
                                  child: const Icon(Icons.person_rounded,
                                      color: AppColors.silverDim, size: 24),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surface,
                                  child: const Icon(Icons.person_rounded,
                                      color: AppColors.silverDim, size: 24),
                                ),
                              )
                            : Container(
                                color: AppColors.surface,
                                child: Center(
                                  child: Text(
                                    title.isNotEmpty
                                        ? title[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.silver,
                                    ),
                                  ),
                                ),
                              ),
          ),
        ),
        if (isOnline && !isGroup && !isChannel && !isSaved)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.online.withOpacity(0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 24) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) {
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[dt.weekday % 7];
    }
    return '${dt.day}/${dt.month}';
  }
}

class _ReadReceiptIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.done_all_rounded,
        size: 14, color: AppColors.readReceipt);
  }
}
