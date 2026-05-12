// File: lib/features/chat/widgets/reply_preview.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';

class ReplyPreview extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onCancel;

  const ReplyPreview({
    super.key,
    required this.message,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.glassBorder, width: 0.5),
          right: BorderSide(color: AppColors.neonRed, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.senderName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neonRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.text ?? '[وسائط]',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.close_rounded,
                color: AppColors.silverDim, size: 18),
          ),
        ],
      ),
    );
  }
}
