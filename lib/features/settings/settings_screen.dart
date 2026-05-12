// File: lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_widgets.dart';
import '../../core/utils/id_generator.dart';
import '../../models/message_edit.dart';
import '../../services/firestore_service.dart';
import '../../services/firestore_service_ext.dart';
import '../auth/providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _appLockEnabled = false;
  String _appVersion = '';
  PrivacySettings _privacy = const PrivacySettings();
  NotificationPrefs _notifPrefs = const NotificationPrefs();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = '${info.version}+${info.buildNumber}');

    final user = ref.read(currentUserProvider);
    if (user != null) {
      _privacy = await ref.read(firestoreServiceProvider).getPrivacySettings(user.id);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _GeneralTab(
                  appVersion: _appVersion,
                  appLockEnabled: _appLockEnabled,
                  onAppLockToggle: _toggleAppLock,
                ),
                _NotificationsTab(
                    prefs: _notifPrefs,
                    onSave: (p) => _saveNotifPrefs(p, user.id)),
                _PrivacyTab(
                    settings: _privacy,
                    onSave: (s) => _savePrivacy(s, user.id)),
                const _QrTab(),
              ],
            ),
          ),
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
          const Text(
            AppStrings.settings,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.silverDim,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
                colors: [AppColors.neonRed, AppColors.darkRed]),
          ),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'عام'),
            Tab(text: 'الإشعارات'),
            Tab(text: 'الخصوصية'),
            Tab(text: 'QR & مشاركة'),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAppLock() async {
    final auth = LocalAuthentication();
    final canAuth = await auth.canCheckBiometrics;
    if (!canAuth) return;
    setState(() => _appLockEnabled = !_appLockEnabled);
  }

  Future<void> _savePrivacy(PrivacySettings s, String userId) async {
    await FirebaseFirestore.instance.savePrivacySettings(userId, s);
    setState(() => _privacy = s);
  }

  Future<void> _saveNotifPrefs(NotificationPrefs p, String userId) async {
    await FirebaseFirestore.instance.saveNotificationPrefs(userId, p);
    setState(() => _notifPrefs = p);
  }
}

// ── QR Tab ────────────────────────────────────────────
class _QrTab extends ConsumerWidget {
  const _QrTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();
    final qrData = 'ilya-chat://user/${user.id}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        const Text('شارك ملفك الشخصي',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          showNeonGlow: true,
          glowIntensity: 0.12,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(
                  data: qrData, version: QrVersions.auto, size: 200,
                  backgroundColor: Colors.white),
            ),
            const SizedBox(height: 14),
            Text('@${user.username}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(IdGenerator.formatId(user.id),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12,
                    color: AppColors.textMuted, letterSpacing: 2)),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: qrData));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ الرابط')));
            },
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 14),
              borderRadius: 14,
              child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_rounded, color: AppColors.silver, size: 18),
                    SizedBox(width: 8),
                    Text('نسخ', style: TextStyle(fontFamily: 'Cairo',
                        fontSize: 13, color: AppColors.textPrimary)),
                  ]),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () => Share.share('تواصل معي على ILYA-Chat!\n\$qrData'),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 14),
              borderRadius: 14,
              borderColor: AppColors.neonRed.withOpacity(0.4),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, color: AppColors.neonRed, size: 18),
                    SizedBox(width: 8),
                    Text('مشاركة', style: TextStyle(fontFamily: 'Cairo',
                        fontSize: 13, color: AppColors.neonRed)),
                  ]),
            ),
          )),
        ]),
      ]),
    );
  }
}
