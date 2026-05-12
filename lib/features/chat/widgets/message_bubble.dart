// File: lib/features/chat/widgets/message_bubble.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final int bubbleShape;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.bubbleShape,
    this.onReply,
    this.onDelete,
    this.onCopy,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glow;
  double _swipeDx = 0;
  bool _showGlow = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _glow = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _showMenu(BuildContext context) {
    setState(() => _showGlow = true);
    _glowCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 600),
        () => setState(() => _showGlow = false));
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageContextMenu(
        message: widget.message,
        isMe: widget.isMe,
        onReply: widget.onReply,
        onCopy: widget.onCopy,
        onDelete: widget.onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    if (msg.isDeleted) {
      return _deletedBubble();
    }

    return GestureDetector(
      onLongPress: () => _showMenu(context),
      onHorizontalDragUpdate: (d) {
        if (!widget.isMe && d.delta.dx > 0) {
          setState(() => _swipeDx = (_swipeDx + d.delta.dx).clamp(0, 60));
        } else if (widget.isMe && d.delta.dx < 0) {
          setState(() => _swipeDx = (_swipeDx + d.delta.dx.abs()).clamp(0, 60));
        }
      },
      onHorizontalDragEnd: (d) {
        if (_swipeDx >= 50) {
          HapticFeedback.lightImpact();
          widget.onReply?.call();
        }
        setState(() => _swipeDx = 0);
      },
      child: AnimatedBuilder(
        animation: _glow,
        builder: (ctx, child) {
          return Transform.translate(
            offset: Offset(
              widget.isMe ? -_swipeDx : _swipeDx,
              0,
            ),
            child: Stack(
              children: [
                if (_showGlow)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.neonRed
                            .withOpacity(0.06 * _glow.value),
                      ),
                    ),
                  ),
                child!,
              ],
            ),
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: widget.isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe) ...[
                _swipeDx > 20
                    ? const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.reply_rounded,
                            color: AppColors.neonRed, size: 18),
                      )
                    : const SizedBox(width: 6),
                const SizedBox(width: 4),
              ],
              Flexible(child: _buildBubble(context)),
              if (widget.isMe) ...[
                const SizedBox(width: 4),
                _swipeDx > 20
                    ? const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.reply_rounded,
                            color: AppColors.neonRed, size: 18),
                      )
                    : const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _deletedBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: widget.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.glassFill,
              border:
                  Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_rounded,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 6),
                Text(
                  widget.isMe ? 'حذفت هذه الرسالة' : 'تم حذف هذه الرسالة',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    final msg = widget.message;
    final radius = _getBubbleRadius();

    return CustomPaint(
      painter: _BubbleTailPainter(
        isMe: widget.isMe,
        shape: widget.bubbleShape,
        color: widget.isMe
            ? AppColors.myBubble
            : AppColors.otherBubble,
        borderColor: widget.isMe
            ? AppColors.myBubbleBorder
            : AppColors.otherBubbleBorder,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? AppColors.myBubble
                  : AppColors.otherBubble,
              borderRadius: radius,
              border: Border.all(
                color: widget.isMe
                    ? AppColors.myBubbleBorder
                    : AppColors.otherBubbleBorder,
                width: 0.7,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.replyToId != null) _buildReplyQuote(msg),
                _buildContent(msg),
                const SizedBox(height: 3),
                _buildMeta(msg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _getBubbleRadius() {
    final shapes = [
      // 0: default telegram-like
      widget.isMe
          ? const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
      // 1: fully rounded
      BorderRadius.circular(20),
      // 2: sharp corners
      BorderRadius.circular(6),
      // 3: bubble
      BorderRadius.circular(22),
      // 4: flat
      BorderRadius.circular(4),
      // 5: creative
      widget.isMe
          ? const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
      // 6: simple
      BorderRadius.circular(12),
    ];
    return shapes[widget.bubbleShape.clamp(0, shapes.length - 1)];
  }

  Widget _buildReplyQuote(MessageModel msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.neonRed.withOpacity(0.1),
        border: Border(
            left: BorderSide(color: AppColors.neonRed, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.replyToSender ?? '',
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.neonRed,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            msg.replyToText ?? '',
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MessageModel msg) {
    switch (msg.type) {
      case MessageType.text:
        return Text(
          msg.text ?? '',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        );
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: msg.mediaUrl ?? '',
            width: 220,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 220,
              height: 160,
              color: AppColors.surface,
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.neonRed, strokeWidth: 2),
              ),
            ),
          ),
        );
      case MessageType.audio:
        return _AudioBubble(
            url: msg.mediaUrl ?? '',
            duration: msg.audioDuration ?? 0,
            isSelfDestruct: msg.isSelfDestruct,
            isMe: widget.isMe);
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                color: AppColors.silver, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                msg.fileName ?? 'ملف',
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textPrimary),
                maxLines: 2,
              ),
            ),
          ],
        );
      default:
        return Text(
          msg.text ?? '',
          style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 14, color: AppColors.textPrimary),
        );
    }
  }

  Widget _buildMeta(MessageModel msg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (msg.isSelfDestruct)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.timer_outlined,
                color: AppColors.neonRed, size: 12),
          ),
        Text(
          _formatTime(msg.createdAt),
          style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: AppColors.textMuted),
        ),
        if (widget.isMe) ...[
          const SizedBox(width: 4),
          Icon(
            msg.status == MessageStatus.read
                ? Icons.done_all_rounded
                : msg.status == MessageStatus.delivered
                    ? Icons.done_all_rounded
                    : Icons.done_rounded,
            size: 14,
            color: msg.status == MessageStatus.read
                ? AppColors.readReceipt
                : AppColors.sentReceipt,
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Audio Bubble ──────────────────────────────────────
class _AudioBubble extends StatelessWidget {
  final String url;
  final int duration;
  final bool isSelfDestruct;
  final bool isMe;

  const _AudioBubble({
    required this.url,
    required this.duration,
    required this.isSelfDestruct,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonRed.withOpacity(0.15),
              border: Border.all(
                  color: AppColors.neonRed.withOpacity(0.4), width: 1),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: AppColors.neonRed,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Waveform visualization
            Row(
              children: List.generate(20, (i) {
                final h = 4.0 + (i % 5) * 3.0;
                return Container(
                  width: 3,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: AppColors.neonRed.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: AppColors.textMuted),
                ),
                if (isSelfDestruct) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.timer_outlined,
                      color: AppColors.neonRed, size: 12),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ── Bubble Tail Painter ────────────────────────────────
class _BubbleTailPainter extends CustomPainter {
  final bool isMe;
  final int shape;
  final Color color;
  final Color borderColor;

  _BubbleTailPainter({
    required this.isMe,
    required this.shape,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shape != 0) return; // Only draw tail for default shape
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final path = Path();
    if (isMe) {
      path
        ..moveTo(size.width - 4, size.height - 2)
        ..lineTo(size.width + 6, size.height + 2)
        ..lineTo(size.width - 4, size.height - 12)
        ..close();
    } else {
      path
        ..moveTo(4, size.height - 2)
        ..lineTo(-6, size.height + 2)
        ..lineTo(4, size.height - 12)
        ..close();
    }
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.isMe != isMe || old.color != color;
}

// ── Context Menu ──────────────────────────────────────
class _MessageContextMenu extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  const _MessageContextMenu({
    required this.message,
    required this.isMe,
    this.onReply,
    this.onCopy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: AppColors.silverDim,
                  borderRadius: BorderRadius.circular(2)),
            ),
            _MenuItem(
              icon: Icons.reply_rounded,
              label: AppStrings.reply,
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            if (message.type == MessageType.text)
              _MenuItem(
                icon: Icons.copy_rounded,
                label: AppStrings.copy,
                onTap: () {
                  Navigator.pop(context);
                  onCopy?.call();
                },
              ),
            _MenuItem(
              icon: Icons.forward_rounded,
              label: AppStrings.forward,
              onTap: () => Navigator.pop(context),
            ),
            if (isMe)
              _MenuItem(
                icon: Icons.delete_outline_rounded,
                label: AppStrings.delete,
                color: AppColors.neonRed,
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.color = AppColors.silver,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color == AppColors.silver
                        ? AppColors.textPrimary
                        : color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

