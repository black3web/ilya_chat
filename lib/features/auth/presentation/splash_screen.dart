// File: lib/features/auth/presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );

    _logoCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2500), () async {
      await _fadeCtrl.forward();
      if (!mounted) return;
      await _navigate();
    });
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLang = prefs.containsKey('language');
    final currentUser = ref.read(currentUserProvider);

    if (!mounted) return;
    if (currentUser != null) {
      context.go('/home');
    } else if (!hasLang) {
      context.go('/language');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background radial gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Color(0xFF1A0008),
                    AppColors.background,
                  ],
                ),
              ),
            ),
            // Animated particles (simple dots)
            _ParticlesBackground(glowAnim: _glowAnim),
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (ctx, _) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.neonRed
                                      .withOpacity(0.5 * _glowAnim.value),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: AppColors.neonRed
                                      .withOpacity(0.2 * _glowAnim.value),
                                  blurRadius: 80,
                                  spreadRadius: 16,
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: _LogoPainter(
                                  glowOpacity: _glowAnim.value),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const AppLogoText(fontSize: 36),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                // Copyright
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      Text(
                        AppStrings.appVersion,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.silverDim,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.copyright,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Loading bar at bottom
            Positioned(
              bottom: 60,
              left: 80,
              right: 80,
              child: _AnimatedLoadingBar(ctrl: _logoCtrl),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo Painter ──────────────────────────────────────
class _LogoPainter extends CustomPainter {
  final double glowOpacity;
  _LogoPainter({required this.glowOpacity});

  @override
  void paint(Canvas canvas, Size s) {
    final glowPaint = Paint()
      ..color = AppColors.neonRed.withOpacity(glowOpacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1A0A0A), Color(0xFF2A0010)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
    final borderPaint = Paint()
      ..color = AppColors.neonRed.withOpacity(0.7 + 0.3 * glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Circle background
    canvas.drawCircle(s.center(Offset.zero), s.width / 2, fillPaint);
    canvas.drawCircle(s.center(Offset.zero), s.width / 2, glowPaint);
    canvas.drawCircle(s.center(Offset.zero), s.width / 2 - 1, borderPaint);

    // Letter I stylized
    final letterPaint = Paint()
      ..color = AppColors.neonRed
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
          BlurStyle.normal, 4 * glowOpacity);

    final path = Path()
      ..moveTo(s.width * 0.42, s.height * 0.25)
      ..lineTo(s.width * 0.58, s.height * 0.25)
      ..lineTo(s.width * 0.58, s.height * 0.4)
      ..lineTo(s.width * 0.54, s.height * 0.4)
      ..lineTo(s.width * 0.54, s.height * 0.6)
      ..lineTo(s.width * 0.58, s.height * 0.6)
      ..lineTo(s.width * 0.58, s.height * 0.75)
      ..lineTo(s.width * 0.42, s.height * 0.75)
      ..lineTo(s.width * 0.42, s.height * 0.6)
      ..lineTo(s.width * 0.46, s.height * 0.6)
      ..lineTo(s.width * 0.46, s.height * 0.4)
      ..lineTo(s.width * 0.42, s.height * 0.4)
      ..close();
    canvas.drawPath(path, letterPaint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.glowOpacity != glowOpacity;
}

// ── Particles Background ──────────────────────────────
class _ParticlesBackground extends StatelessWidget {
  final Animation<double> glowAnim;
  const _ParticlesBackground({required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnim,
      builder: (ctx, _) {
        return CustomPaint(
          painter: _ParticlesPainter(t: glowAnim.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double t;
  _ParticlesPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const positions = [
      [0.1, 0.15], [0.9, 0.2], [0.05, 0.6], [0.95, 0.55],
      [0.2, 0.85], [0.8, 0.9], [0.5, 0.08], [0.3, 0.5],
      [0.7, 0.45], [0.15, 0.4], [0.85, 0.7],
    ];
    for (var i = 0; i < positions.length; i++) {
      final phase = (t + i * 0.09) % 1.0;
      final opacity = (0.5 + 0.5 * phase).clamp(0.0, 1.0);
      final radius = 1.5 + phase * 1.5;
      paint.color = AppColors.neonRed.withOpacity(opacity * 0.3);
      canvas.drawCircle(
        Offset(size.width * positions[i][0], size.height * positions[i][1]),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => old.t != t;
}

// ── Animated Loading Bar ──────────────────────────────
class _AnimatedLoadingBar extends StatelessWidget {
  final AnimationController ctrl;
  const _AnimatedLoadingBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        return Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: AppColors.surface,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ctrl.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: const LinearGradient(
                  colors: [AppColors.neonRed, Colors.white],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonRed.withOpacity(0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
