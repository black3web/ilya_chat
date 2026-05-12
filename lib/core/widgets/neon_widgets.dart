// File: lib/core/widgets/neon_widgets.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// ── Neon Text ─────────────────────────────────────────
class NeonText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final double glowRadius;
  final TextAlign? textAlign;

  const NeonText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.color = AppColors.neonRed,
    this.glowRadius = 12,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        shadows: [
          Shadow(blurRadius: glowRadius, color: color.withOpacity(0.8)),
          Shadow(blurRadius: glowRadius * 2, color: color.withOpacity(0.4)),
          Shadow(blurRadius: glowRadius * 4, color: color.withOpacity(0.2)),
        ],
      ),
    );
  }
}

// ── App Logo Text ─────────────────────────────────────
class AppLogoText extends StatelessWidget {
  final double fontSize;

  const AppLogoText({super.key, this.fontSize = 28});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'ILYA',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: const [
                Shadow(blurRadius: 8, color: Colors.white38),
              ],
            ),
          ),
          TextSpan(
            text: '-',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.neonRed,
              shadows: [
                Shadow(
                    blurRadius: 12,
                    color: AppColors.neonRed.withOpacity(0.8)),
              ],
            ),
          ),
          TextSpan(
            text: 'Chat',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.neonRed,
              shadows: [
                Shadow(
                    blurRadius: 12,
                    color: AppColors.neonRed.withOpacity(0.8)),
                Shadow(
                    blurRadius: 24,
                    color: AppColors.neonRed.withOpacity(0.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Neon Button ───────────────────────────────────────
class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final Color color;
  final double fontSize;

  const NeonButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.color = AppColors.neonRed,
    this.fontSize = 15,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        if (!widget.isLoading) widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: widget.width ?? double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                widget.color,
                widget.color.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 32,
                spreadRadius: -4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withOpacity(0.9),
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          blurRadius: 8,
                          color: Colors.white.withOpacity(0.4)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Superuser Crown Badge ─────────────────────────────
class CrownBadge extends StatefulWidget {
  final double size;
  const CrownBadge({super.key, this.size = 18});

  @override
  State<CrownBadge> createState() => _CrownBadgeState();
}

class _CrownBadgeState extends State<CrownBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CrownPainter(glowOpacity: _glow.value),
          ),
        );
      },
    );
  }
}

class _CrownPainter extends CustomPainter {
  final double glowOpacity;
  _CrownPainter({required this.glowOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glowPaint = Paint()
      ..color = AppColors.neonRed.withOpacity(glowOpacity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.superuserCrown, AppColors.superuserCrownAccent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path()
      ..moveTo(0, h * 0.75)
      ..lineTo(w * 0.1, h * 0.35)
      ..lineTo(w * 0.3, h * 0.6)
      ..lineTo(w * 0.5, h * 0.1)
      ..lineTo(w * 0.7, h * 0.6)
      ..lineTo(w * 0.9, h * 0.35)
      ..lineTo(w, h * 0.75)
      ..close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, fillPaint);

    // Jewel dots
    final dotPaint = Paint()..color = AppColors.neonRed.withOpacity(glowOpacity);
    canvas.drawCircle(Offset(w * 0.5, h * 0.18), w * 0.07, dotPaint);
    canvas.drawCircle(Offset(w * 0.1, h * 0.38), w * 0.05, dotPaint);
    canvas.drawCircle(Offset(w * 0.9, h * 0.38), w * 0.05, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) =>
      old.glowOpacity != glowOpacity;
}

// ── Custom SVG-style Icons ────────────────────────────
class AppIcon extends StatelessWidget {
  final AppIconType type;
  final double size;
  final Color color;

  const AppIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.color = AppColors.silver,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppIconPainter(type: type, color: color),
      ),
    );
  }
}

enum AppIconType {
  send,
  mic,
  attach,
  camera,
  sticker,
  reply,
  more,
  search,
  close,
  back,
  checkSingle,
  checkDouble,
  checkRead,
  hamburger,
  story,
  channel,
  group,
  saved,
  settings,
  edit,
  trash,
  phone,
  video,
  mute,
  pin,
  forward,
}

class _AppIconPainter extends CustomPainter {
  final AppIconType type;
  final Color color;

  _AppIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = s.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case AppIconType.send:
        final path = Path()
          ..moveTo(s.width * 0.1, s.height * 0.5)
          ..lineTo(s.width * 0.9, s.height * 0.3)
          ..lineTo(s.width * 0.1, s.height * 0.1)
          ..close();
        canvas.drawPath(path, p);
        canvas.drawLine(Offset(s.width * 0.1, s.height * 0.5),
            Offset(s.width * 0.5, s.height * 0.8), p);
        break;

      case AppIconType.mic:
        final rrect = RRect.fromLTRBR(s.width * 0.35, s.height * 0.1,
            s.width * 0.65, s.height * 0.65, Radius.circular(s.width * 0.15));
        canvas.drawRRect(rrect, p);
        final arc = Path()
          ..moveTo(s.width * 0.2, s.height * 0.55)
          ..quadraticBezierTo(s.width * 0.2, s.height * 0.85,
              s.width * 0.5, s.height * 0.85)
          ..quadraticBezierTo(s.width * 0.8, s.height * 0.85,
              s.width * 0.8, s.height * 0.55);
        canvas.drawPath(arc, p);
        canvas.drawLine(Offset(s.width * 0.5, s.height * 0.85),
            Offset(s.width * 0.5, s.height * 0.95), p);
        break;

      case AppIconType.hamburger:
        for (var i = 0; i < 3; i++) {
          final y = s.height * (0.25 + i * 0.25);
          canvas.drawLine(
              Offset(s.width * 0.15, y), Offset(s.width * 0.85, y), p);
        }
        break;

      case AppIconType.search:
        canvas.drawCircle(
            Offset(s.width * 0.42, s.height * 0.42),
            s.width * 0.28,
            p);
        canvas.drawLine(
            Offset(s.width * 0.63, s.height * 0.63),
            Offset(s.width * 0.88, s.height * 0.88),
            p);
        break;

      case AppIconType.close:
        canvas.drawLine(Offset(s.width * 0.2, s.height * 0.2),
            Offset(s.width * 0.8, s.height * 0.8), p);
        canvas.drawLine(Offset(s.width * 0.8, s.height * 0.2),
            Offset(s.width * 0.2, s.height * 0.8), p);
        break;

      case AppIconType.back:
        canvas.drawLine(Offset(s.width * 0.6, s.height * 0.2),
            Offset(s.width * 0.2, s.height * 0.5), p);
        canvas.drawLine(Offset(s.width * 0.2, s.height * 0.5),
            Offset(s.width * 0.6, s.height * 0.8), p);
        break;

      case AppIconType.checkSingle:
        canvas.drawLine(Offset(s.width * 0.15, s.height * 0.55),
            Offset(s.width * 0.42, s.height * 0.8), p);
        canvas.drawLine(Offset(s.width * 0.42, s.height * 0.8),
            Offset(s.width * 0.85, s.height * 0.25), p);
        break;

      case AppIconType.checkDouble:
        final p2 = Paint()
          ..color = color
          ..strokeWidth = s.width * 0.07
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(s.width * 0.05, s.height * 0.55),
            Offset(s.width * 0.32, s.height * 0.8), p2);
        canvas.drawLine(Offset(s.width * 0.32, s.height * 0.8),
            Offset(s.width * 0.65, s.height * 0.25), p2);
        canvas.drawLine(Offset(s.width * 0.35, s.height * 0.55),
            Offset(s.width * 0.55, s.height * 0.75), p2);
        canvas.drawLine(Offset(s.width * 0.55, s.height * 0.75),
            Offset(s.width * 0.92, s.height * 0.25), p2);
        break;

      case AppIconType.edit:
        final path = Path()
          ..moveTo(s.width * 0.6, s.height * 0.15)
          ..lineTo(s.width * 0.85, s.height * 0.4)
          ..lineTo(s.width * 0.35, s.height * 0.9)
          ..lineTo(s.width * 0.1, s.height * 0.9)
          ..lineTo(s.width * 0.1, s.height * 0.65)
          ..close();
        canvas.drawPath(path, p);
        break;

      case AppIconType.trash:
        canvas.drawLine(Offset(s.width * 0.15, s.height * 0.3),
            Offset(s.width * 0.85, s.height * 0.3), p);
        final rect = RRect.fromLTRBR(s.width * 0.25, s.height * 0.3,
            s.width * 0.75, s.height * 0.9, Radius.circular(s.width * 0.06));
        canvas.drawRRect(rect, p);
        canvas.drawLine(Offset(s.width * 0.4, s.height * 0.15),
            Offset(s.width * 0.6, s.height * 0.15), p);
        for (var x in [0.4, 0.5, 0.6]) {
          canvas.drawLine(Offset(s.width * x, s.height * 0.45),
              Offset(s.width * x, s.height * 0.78), p);
        }
        break;

      case AppIconType.settings:
        canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.5),
            s.width * 0.18, p);
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final x1 = s.width * 0.5 + s.width * 0.28 * math.cos(angle);
          final y1 = s.height * 0.5 + s.height * 0.28 * math.sin(angle);
          final x2 = s.width * 0.5 + s.width * 0.42 * math.cos(angle);
          final y2 = s.height * 0.5 + s.height * 0.42 * math.sin(angle);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
        }
        break;

      case AppIconType.attach:
        final path = Path()
          ..moveTo(s.width * 0.55, s.height * 0.35)
          ..lineTo(s.width * 0.35, s.height * 0.7)
          ..quadraticBezierTo(s.width * 0.2, s.height * 0.9,
              s.width * 0.45, s.height * 0.9)
          ..quadraticBezierTo(
              s.width * 0.8, s.height * 0.9, s.width * 0.8, s.height * 0.5)
          ..lineTo(s.width * 0.8, s.height * 0.25)
          ..quadraticBezierTo(s.width * 0.8, s.height * 0.1,
              s.width * 0.5, s.height * 0.1)
          ..quadraticBezierTo(s.width * 0.15, s.height * 0.1,
              s.width * 0.15, s.height * 0.5);
        canvas.drawPath(path, p);
        break;

      default:
        canvas.drawCircle(
            Offset(s.width / 2, s.height / 2), s.width * 0.4, p);
        break;
    }
  }


  @override
  bool shouldRepaint(covariant _AppIconPainter old) =>
      old.color != color || old.type != type;
}
