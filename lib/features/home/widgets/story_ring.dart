// File: lib/features/home/widgets/story_ring.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';

class StoryRing extends StatelessWidget {
  final String userId;
  final String? avatarUrl;
  final String name;
  final List<StoryModel> stories;
  final bool isOwn;
  final String currentUserId;

  const StoryRing({
    super.key,
    required this.userId,
    this.avatarUrl,
    required this.name,
    required this.stories,
    required this.isOwn,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final hasStories = stories.isNotEmpty;
    final allSeen = hasStories &&
        stories.every((s) => s.viewedBy.contains(currentUserId));
    final ringColor =
        !hasStories || allSeen ? AppColors.storySeen : AppColors.storyUnseen;

    return GestureDetector(
      onTap: () {
        if (isOwn && !hasStories) {
          _showAddStory(context);
        } else if (hasStories) {
          _viewStories(context);
        }
      },
      child: Container(
        width: 68,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Ring
                CustomPaint(
                  size: const Size(58, 58),
                  painter: _StoryRingPainter(
                    segmentCount: stories.isEmpty ? 1 : stories.length,
                    seenCount: stories
                        .where((s) => s.viewedBy.contains(currentUserId))
                        .length,
                    color: ringColor,
                    hasStories: hasStories,
                  ),
                ),
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.background, width: 2),
                  ),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.surface,
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.silver,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                // Add story button
                if (isOwn)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.neonRed,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.background, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonRed.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              isOwn ? 'قصتي' : name,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStorySheet(userId: userId),
    );
  }

  void _viewStories(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => StoryViewerScreen(
          stories: stories,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}

// ── Story Ring Painter ────────────────────────────────
class _StoryRingPainter extends CustomPainter {
  final int segmentCount;
  final int seenCount;
  final Color color;
  final bool hasStories;

  _StoryRingPainter({
    required this.segmentCount,
    required this.seenCount,
    required this.color,
    required this.hasStories,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final gap = segmentCount > 1 ? 0.08 : 0;
    final segAngle = (2 * 3.14159) / segmentCount - gap;

    for (int i = 0; i < segmentCount; i++) {
      final startAngle = -3.14159 / 2 + i * (2 * 3.14159) / segmentCount;
      final isSeen = i < seenCount;
      final paint = Paint()
        ..color = isSeen ? AppColors.storySeen : AppColors.storyUnseen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      if (!hasStories) {
        paint.color = AppColors.storySeen;
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StoryRingPainter old) =>
      old.seenCount != seenCount || old.segmentCount != segmentCount;
}

// ── Story Viewer ──────────────────────────────────────
class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final String currentUserId;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.currentUserId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _nextStory();
      });
    _progressCtrl.forward();
  }

  void _nextStory() {
    if (_index < widget.stories.length - 1) {
      setState(() => _index++);
      _progressCtrl.reset();
      _progressCtrl.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_index > 0) {
      setState(() => _index--);
      _progressCtrl.reset();
      _progressCtrl.forward();
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Story image
          CachedNetworkImage(
            imageUrl: story.mediaUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
          ),
          // Tap zones
          Row(
            children: [
              Expanded(
                  child: GestureDetector(onTap: _prevStory)),
              Expanded(
                  child: GestureDetector(onTap: _nextStory)),
            ],
          ),
          // Progress bars
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: Row(
                    children: List.generate(widget.stories.length, (i) {
                      return Expanded(
                        child: Container(
                          height: 2.5,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.white24,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: i < _index
                                ? Container(color: Colors.white)
                                : i == _index
                                    ? AnimatedBuilder(
                                        animation: _progressCtrl,
                                        builder: (_, __) =>
                                            FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _progressCtrl.value,
                                          child: Container(
                                              color: Colors.white),
                                        ),
                                      )
                                    : const SizedBox(),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // User info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surface,
                        backgroundImage: story.userAvatar != null
                            ? CachedNetworkImageProvider(story.userAvatar!)
                            : null,
                        child: story.userAvatar == null
                            ? Text(story.userDisplayName[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        story.userDisplayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Caption
          if (story.caption != null)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Text(
                story.caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Add Story Sheet ───────────────────────────────────
class _AddStorySheet extends StatelessWidget {
  final String userId;
  const _AddStorySheet({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.silverDim,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'إضافة قصة',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StoryOption(
                icon: Icons.photo_library_outlined,
                label: 'الصور',
                onTap: () => Navigator.pop(context),
              ),
              _StoryOption(
                icon: Icons.videocam_outlined,
                label: 'الفيديو',
                onTap: () => Navigator.pop(context),
              ),
              _StoryOption(
                icon: Icons.camera_alt_outlined,
                label: 'الكاميرا',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StoryOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StoryOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonRed.withOpacity(0.1),
              border: Border.all(
                  color: AppColors.neonRed.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: AppColors.neonRed, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
