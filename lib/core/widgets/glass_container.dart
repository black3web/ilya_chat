// File: lib/core/widgets/glass_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final double blurSigma;
  final Color? fillColor;
  final bool showNeonGlow;
  final double glowIntensity;
  final Color glowColor;
  final BorderRadiusGeometry? customBorderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.borderColor,
    this.borderWidth = 0.8,
    this.blurSigma = 12,
    this.fillColor,
    this.showNeonGlow = false,
    this.glowIntensity = 0.3,
    this.glowColor = AppColors.neonRed,
    this.customBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = customBorderRadius ?? BorderRadius.circular(borderRadius);
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: showNeonGlow
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(glowIntensity),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: glowColor.withOpacity(glowIntensity * 0.5),
                  blurRadius: 40,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor ?? AppColors.glassFill,
              borderRadius: br,
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Neon Border Glow Container ────────────────────────
class NeonGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color glowColor;
  final double blurSigma;

  const NeonGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.glowColor = AppColors.neonRed,
    this.blurSigma = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: glowColor.withOpacity(0.2),
            blurRadius: 32,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: glowColor.withOpacity(0.6),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Shimmer Placeholder ───────────────────────────────
class GlassShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const GlassShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<GlassShimmer> createState() => _GlassShimmerState();
}

class _GlassShimmerState extends State<GlassShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
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
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: const [
                Color(0x0AFFFFFF),
                Color(0x1AFFFFFF),
                Color(0x0AFFFFFF),
              ],
            ),
          ),
        );
      },
    );
  }
}
