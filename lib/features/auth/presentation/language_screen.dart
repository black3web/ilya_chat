// File: lib/features/auth/presentation/language_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../providers/providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [Color(0xFF1A0008), AppColors.background],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogoText(fontSize: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'اختر لغتك المفضلة\nChoose your language',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Arabic
                  _LanguageTile(
                    flag: '🇮🇶',
                    name: 'العربية',
                    subtitle: 'اللغة العربية',
                    code: 'ar',
                    onTap: () async {
                      await ref.read(languageProvider.notifier).setLanguage('ar');
                      if (context.mounted) context.go('/login');
                    },
                  ),
                  const SizedBox(height: 16),
                  // English
                  _LanguageTile(
                    flag: '🇺🇸',
                    name: 'English',
                    subtitle: 'English Language',
                    code: 'en',
                    onTap: () async {
                      await ref.read(languageProvider.notifier).setLanguage('en');
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatefulWidget {
  final String flag;
  final String name;
  final String subtitle;
  final String code;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.name,
    required this.subtitle,
    required this.code,
    required this.onTap,
  });

  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.reverse();
        setState(() => _hovered = true);
      },
      onTapUp: (_) {
        _ctrl.forward();
        setState(() => _hovered = false);
        widget.onTap();
      },
      onTapCancel: () {
        _ctrl.forward();
        setState(() => _hovered = false);
      },
      child: ScaleTransition(
        scale: _ctrl,
        child: NeonGlassContainer(
          borderRadius: 18,
          glowColor: _hovered ? AppColors.neonRed : AppColors.glassBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Text(
                  widget.flag,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _hovered
                          ? AppColors.neonRed
                          : AppColors.glassBorder,
                      width: 1.5,
                    ),
                    color: _hovered
                        ? AppColors.neonRedFaint
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: _hovered
                        ? AppColors.neonRed
                        : AppColors.silverDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
