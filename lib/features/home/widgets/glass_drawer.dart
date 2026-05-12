// lib/features/home/widgets/glass_drawer.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/providers.dart';
class GlassDrawer extends ConsumerWidget {
  final UserModel user;
  final VoidCallback onClose;

  const GlassDrawer({super.key, required this.user, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 290,
        height: double.infinity,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.92),
                border: Border(
                  right: BorderSide(
                    color: AppColors.neonRed.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonRed.withOpacity(0.08),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(10, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Profile Banner
                    _ProfileBanner(user: user, onClose: onClose),
                    const Divider(
                        height: 1, color: AppColors.glassBorder, thickness: 0.5),
                    // Menu Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _DrawerItem(
                            icon: Icons.bookmark_rounded,
                            label: AppStrings.saved,
                            color: AppColors.neonRed,
                            onTap: () {
                              onClose();
                              final chatId = '${user.id}_saved';
                              context.push('/chat/$chatId', extra: {
                                'otherUserId': user.id,
                                'otherUserName': AppStrings.saved,
                                'otherUserAvatar': null,
                              });
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.search_rounded,
                            label: 'البحث العالمي',
                            onTap: () { onClose(); context.push('/search'); },
                          ),
                          _DrawerItem(
                            icon: Icons.folder_outlined,
                            label: 'المجلدات',
                            onTap: () { onClose(); context.push('/folders'); },
                          ),
                          _DrawerItem(
                            icon: Icons.settings_outlined,
                            label: AppStrings.settings,
                            onTap: () { onClose(); context.push('/settings'); },
                          ),
                          _DrawerItem(
                            icon: Icons.people_outline_rounded,
                            label: AppStrings.groups,
                            onTap: () => onClose(),
                          ),
                          _DrawerItem(
                            icon: Icons.campaign_outlined,
                            label: AppStrings.channels,
                            onTap: () => onClose(),
                          ),
                          _DrawerItem(
                            icon: Icons.folder_outlined,
                            label: AppStrings.folders,
                            onTap: () => onClose(),
                          ),
                          if (user.isSuperuser) ...[
                            const Divider(height:1,color:AppColors.glassBorder,thickness:0.5,indent:16,endIndent:16),
                            _DrawerItem(
                              icon: Icons.admin_panel_settings_outlined,
                              label: 'لوحة المبرمج',
                              color: AppColors.neonRed,
                              onTap: () { onClose(); context.push('/superuser'); },
                            ),
                            _DrawerItem(
                              icon: Icons.delete_sweep_outlined,
                              label: 'الرسائل المحذوفة',
                              color: AppColors.neonRed,
                              onTap: () { onClose(); context.push('/deleted-messages'); },
                            ),
                          ],
                          const Divider(
                              height: 1,
                              color: AppColors.glassBorder,
                              thickness: 0.5,
                              indent: 16,
                              endIndent: 16),
                          _DrawerItem(
                            icon: Icons.logout_rounded,
                            label: AppStrings.logout,
                            color: AppColors.neonRed,
                            onTap: () async {
                              onClose();
                              await ref.read(currentUserProvider.notifier).logout();
                              if (context.mounted) context.go('/login');
                            },
                          ),
                        ],
                      ),
                    ),
                    // Version
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${AppStrings.appName} ${AppStrings.appVersion}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
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

}

// ── Profile Banner ────────────────────────────────────
class _ProfileBanner extends StatelessWidget {
  final UserModel user;
  final VoidCallback onClose;

  const _ProfileBanner({required this.user, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onClose();
        context.push('/profile/${user.id}');
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.neonRed.withOpacity(0.1),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonRed.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonRed.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: user.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.surfaceLight,
                        child: Center(
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.silver,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (user.isSuperuser) ...[
                        const CrownBadge(size: 16),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.neonRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: user.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.idCopied),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Text(
                      'ID: ${IdGenerator.formatId(user.id)}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.silverDim, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Drawer Item ───────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerItem({
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
        splashColor: AppColors.neonRed.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
                      : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
