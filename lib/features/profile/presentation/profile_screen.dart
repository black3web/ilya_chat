// File: lib/features/profile/presentation/profile_screen.dart
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isEditing = false;
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userStreamProvider(widget.userId));
    final isOwn = currentUser?.id == widget.userId;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
                child: Text('المستخدم غير موجود',
                    style: TextStyle(
                        fontFamily: 'Cairo', color: AppColors.textPrimary))),
          );
        }
        if (!_isEditing) {
          _nameCtrl.text = profile.displayName;
          _bioCtrl.text = profile.bio ?? '';
        }
        return _buildProfile(profile, isOwn, currentUser);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.neonRed)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: Text(e.toString(),
                style: const TextStyle(color: AppColors.neonRed))),
      ),
    );
  }

  Widget _buildProfile(UserModel profile, bool isOwn, UserModel? currentUser) {
    final gradColors = AppColors.profileGradients[
        profile.profileGradientIndex.clamp(0, 29)];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar with Background ───────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppColors.silver, size: 20),
            ),
            actions: [
              if (isOwn)
                GestureDetector(
                  onTap: () => setState(() => _isEditing = !_isEditing),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                      color:
                          _isEditing ? AppColors.neonRed : AppColors.silver,
                      size: 22,
                    ),
                  ),
                ),
              if (isOwn && _isEditing)
                GestureDetector(
                  onTap: () => _saveProfile(profile),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Text(
                      'حفظ',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: AppColors.neonRed,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (!isOwn)
                GestureDetector(
                  onTap: () => _showReport(profile, currentUser),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.flag_outlined,
                        color: AppColors.silverDim, size: 20),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: profile.profileGradientDirection == 2
                      ? RadialGradient(
                          center: Alignment.center,
                          radius: 1.0,
                          colors: gradColors,
                        )
                      : LinearGradient(
                          colors: gradColors,
                          begin: profile.profileGradientDirection == 0
                              ? Alignment.topCenter
                              : Alignment.topLeft,
                          end: profile.profileGradientDirection == 0
                              ? Alignment.bottomCenter
                              : Alignment.bottomRight,
                        ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: isOwn ? () => _changeAvatar(profile) : null,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: profile.isSuperuser
                                      ? AppColors.neonRed
                                      : AppColors.glassBorder,
                                  width: 2.5,
                                ),
                                boxShadow: profile.isSuperuser
                                    ? [
                                        BoxShadow(
                                          color: AppColors.neonRed
                                              .withOpacity(0.3),
                                          blurRadius: 16,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ClipOval(
                                child: profile.avatarUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: profile.avatarUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.surfaceLight,
                                        child: Center(
                                          child: Text(
                                            profile.displayName.isNotEmpty
                                                ? profile.displayName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.silver,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            if (isOwn)
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.neonRed,
                                  border: Border.all(
                                      color: AppColors.background,
                                      width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 14, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (profile.isSuperuser) ...[
                            const CrownBadge(size: 18),
                            const SizedBox(width: 6),
                          ],
                          _isEditing && isOwn
                              ? SizedBox(
                                  width: 180,
                                  child: TextField(
                                    controller: _nameCtrl,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                )
                              : Text(
                                  profile.displayName,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    shadows: [
                                      Shadow(blurRadius: 6, color: Colors.black45)
                                    ],
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${profile.username}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.neonRed,
                          shadows: [
                            Shadow(
                                blurRadius: 8,
                                color: AppColors.neonRed)
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Profile Body ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: isOwn
                            ? _actionBtn(
                                Icons.bookmark_rounded,
                                AppStrings.saved,
                                onTap: () =>
                                    context.push('/chat/${profile.id}_saved',
                                        extra: {
                                      'otherUserId': profile.id,
                                      'otherUserName': AppStrings.saved,
                                      'otherUserAvatar': null,
                                    }),
                              )
                            : _actionBtn(
                                Icons.send_rounded,
                                AppStrings.sendMessage,
                                onTap: () {
                                  final fs =
                                      ref.read(firestoreServiceProvider);
                                  final chatId = fs.chatId(
                                      currentUser!.id, profile.id);
                                  context.push('/chat/$chatId', extra: {
                                    'otherUserId': profile.id,
                                    'otherUserName': profile.displayName,
                                    'otherUserAvatar': profile.avatarUrl,
                                  });
                                },
                                color: AppColors.neonRed,
                              ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: profile.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(AppStrings.idCopied)),
                          );
                        },
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 14,
                          child: Column(
                            children: [
                              const Icon(Icons.copy_rounded,
                                  color: AppColors.silver, size: 18),
                              const SizedBox(height: 2),
                              Text(
                                'نسخ ID',
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ID display
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint_rounded,
                            color: AppColors.neonRed, size: 20),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المعرّف الفريد',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                            Text(
                              IdGenerator.formatId(profile.id),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.silver,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'لا يمكن تغييره',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bio
                  GlassContainer(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.bio,
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.neonRed,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        _isEditing && isOwn
                            ? TextField(
                                controller: _bioCtrl,
                                maxLines: 3,
                                maxLength: 150,
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: AppStrings.addBio,
                                  hintStyle: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      color: AppColors.textMuted),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  counterStyle: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10,
                                      color: AppColors.textMuted),
                                ),
                              )
                            : Text(
                                profile.bio?.isNotEmpty == true
                                    ? profile.bio!
                                    : (isOwn
                                        ? AppStrings.addBio
                                        : 'لا توجد نبذة شخصية'),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  color: profile.bio?.isNotEmpty == true
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  height: 1.5,
                                ),
                              ),
                      ],
                    ),
                  ),
                  // Links
                  if (profile.links.isNotEmpty || isOwn) ...[
                    const SizedBox(height: 12),
                    _LinksSection(
                        profile: profile,
                        isOwn: isOwn,
                        isEditing: _isEditing),
                  ],
                  // Theme picker (own only, editing)
                  if (isOwn && _isEditing) ...[
                    const SizedBox(height: 12),
                    _ThemePicker(profile: profile),
                  ],
                  const SizedBox(height: 12),
                  // Tabs
                  GlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabCtrl,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.silverDim,
                      labelStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.neonRed,
                      ),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: AppStrings.stories),
                        Tab(text: AppStrings.media),
                        Tab(text: AppStrings.files),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _MediaGrid(userId: profile.id, type: 'stories'),
                        _MediaGrid(userId: profile.id, type: 'media'),
                        _FilesGrid(userId: profile.id),
                      ],
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

  Widget _actionBtn(IconData icon, String label,
      {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 12),
        borderRadius: 14,
        borderColor:
            color != null ? color.withOpacity(0.4) : AppColors.glassBorder,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? AppColors.silver, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeAvatar(UserModel profile) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final url = await ref
        .read(storageServiceProvider)
        .uploadAvatar(profile.id, File(file.path));
    await ref
        .read(firestoreServiceProvider)
        .updateUser(profile.id, {'avatarUrl': url});
  }

  Future<void> _saveProfile(UserModel profile) async {
    await ref.read(firestoreServiceProvider).updateUser(profile.id, {
      'displayName': _nameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
    });
    setState(() => _isEditing = false);
  }

  void _showReport(UserModel profile, UserModel? reporter) {
    if (reporter == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('الإبلاغ عن المستخدم',
            style: TextStyle(
                fontFamily: 'Cairo', color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر سبب البلاغ:',
                style: TextStyle(
                    fontFamily: 'Cairo', color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ...['محتوى مسيء', 'انتحال شخصية', 'محتوى غير لائق', 'سبام']
                .map((r) => ListTile(
                      dense: true,
                      title: Text(r,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.textPrimary)),
                      onTap: () async {
                        Navigator.pop(context);
                        final ticket = SupportTicket(
                          id: DateTime.now().millisecondsSinceEpoch
                              .toString(),
                          reporterId: reporter.id,
                          reporterName: reporter.displayName,
                          reportedId: profile.id,
                          reportedName: profile.displayName,
                          reason: r,
                          createdAt: DateTime.now(),
                        );
                        await ref
                            .read(firestoreServiceProvider)
                            .submitReport(ticket);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم إرسال البلاغ')),
                          );
                        }
                      },
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}

// ── Links Section ─────────────────────────────────────
class _LinksSection extends StatelessWidget {
  final UserModel profile;
  final bool isOwn;
  final bool isEditing;

  const _LinksSection({
    required this.profile,
    required this.isOwn,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                AppStrings.links,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.neonRed,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (isOwn && isEditing)
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.neonRed, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.links.isEmpty)
            Text(
              isOwn ? AppStrings.addLink : 'لا توجد روابط',
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textMuted),
            )
          else
            ...profile.links.map((link) => _LinkItem(link: link)),
        ],
      ),
    );
  }
}

class _LinkItem extends StatelessWidget {
  final ProfileLink link;
  const _LinkItem({required this.link});

  @override
  Widget build(BuildContext context) {
    final platform =
        LinkDetector.detect(link.url);
    final color =
        AppColors.iconLinkColors[link.colorIndex.clamp(0, 15)];
    final label =
        link.label ?? LinkDetector.platformLabel(platform);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(link.url);
          if (await canLaunchUrl(uri)) launchUrl(uri);
        },
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border:
                    Border.all(color: color.withOpacity(0.4), width: 1),
              ),
              child: Icon(_platformIcon(platform), color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
                Text(
                  link.url,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _platformIcon(LinkPlatform p) {
    switch (p) {
      case LinkPlatform.youtube:
        return Icons.play_circle_outlined;
      case LinkPlatform.github:
        return Icons.code_rounded;
      case LinkPlatform.telegram:
        return Icons.telegram_rounded;
      default:
        return Icons.link_rounded;
    }
  }
}

// ── Theme Picker ──────────────────────────────────────
class _ThemePicker extends ConsumerWidget {
  final UserModel profile;
  const _ThemePicker({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.profileTheme,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.neonRed,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppColors.profileGradients.length,
              itemBuilder: (ctx, i) {
                final colors = AppColors.profileGradients[i];
                final selected = profile.profileGradientIndex == i;
                return GestureDetector(
                  onTap: () async {
                    await ref
                        .read(firestoreServiceProvider)
                        .updateUser(profile.id, {
                      'profileGradientIndex': i,
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      border: Border.all(
                        color: selected
                            ? AppColors.neonRed
                            : AppColors.glassBorder,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Media Grid ────────────────────────────────────────
class _MediaGrid extends StatelessWidget {
  final String userId;
  final String type;
  const _MediaGrid({required this.userId, required this.type});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: 0,
      itemBuilder: (_, i) => Container(color: AppColors.surfaceLight),
    );
  }
}

class _FilesGrid extends StatelessWidget {
  final String userId;
  const _FilesGrid({required this.userId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'لا توجد ملفات',
        style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppColors.textMuted),
      ),
    );
  }
}

