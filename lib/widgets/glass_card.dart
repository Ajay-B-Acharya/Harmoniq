import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Elevation hierarchy for spatial glass materials:
/// - Level 2 (surface): subtle translucent surface with 1px neutral illuminated edge.
/// - Level 3 (floating): slightly more visible glass with top-edge specular highlight & elevation shadow.
/// - Level 4 (active): subtle violet-tinted glass with controlled accent glow.
enum GlassLevel {
  surface,
  floating,
  active,
}

enum GlassTint {
  neutral,
  violet,
  blue,
  selected,
}

/// A rounded physical glass card with precision transparency, physical illuminated
/// edges, top-edge specular highlight, and optional backdrop blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final GlassLevel level;
  final GlassTint tint;
  final bool? specularHighlight;

  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final Color? glowColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 0,
    this.level = GlassLevel.surface,
    this.tint = GlassTint.neutral,
    this.specularHighlight,
    this.color,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.glowColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Resolve surface color from hierarchy & tinting
    final Color surfaceColor;
    if (color != null) {
      surfaceColor = color!;
    } else {
      switch (level) {
        case GlassLevel.active:
          surfaceColor = AppColors.glassSelected; // rgba(168, 85, 247, 0.080)
          break;
        case GlassLevel.floating:
          surfaceColor = AppColors.glassElevated; // rgba(255, 255, 255, 0.055)
          break;
        case GlassLevel.surface:
          switch (tint) {
            case GlassTint.selected:
              surfaceColor = AppColors.glassSelected;
              break;
            case GlassTint.violet:
              surfaceColor = AppColors.glassVioletTint; // rgba(168, 85, 247, 0.045)
              break;
            case GlassTint.blue:
              surfaceColor = AppColors.glassBlueTint; // rgba(96, 165, 250, 0.035)
              break;
            case GlassTint.neutral:
              surfaceColor = AppColors.glassPrimary; // rgba(255, 255, 255, 0.025)
              break;
          }
          break;
      }
    }

    // 2. Resolve border color
    final Color effectiveBorderColor;
    if (borderColor != null) {
      effectiveBorderColor = borderColor!;
    } else {
      switch (level) {
        case GlassLevel.active:
          effectiveBorderColor = AppColors.borderActiveViolet; // rgba(168, 85, 247, 0.50)
          break;
        case GlassLevel.floating:
          effectiveBorderColor = AppColors.borderElevated; // rgba(255, 255, 255, 0.20)
          break;
        case GlassLevel.surface:
          effectiveBorderColor = AppColors.borderStandard; // rgba(255, 255, 255, 0.14)
          break;
      }
    }

    // 3. Resolve shadows
    final List<BoxShadow> shadows;
    if (glowColor != null) {
      shadows = [
        const BoxShadow(
          color: AppColors.shadowStandard,
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: glowColor!.withValues(alpha: 0.20),
          blurRadius: 16,
          offset: const Offset(0, 1),
        ),
      ];
    } else {
      switch (level) {
        case GlassLevel.active:
          shadows = const [
            BoxShadow(
              color: AppColors.shadowActiveViolet, // rgba(168, 85, 247, 0.16)
              blurRadius: 14,
              offset: Offset(0, 1),
            ),
          ];
          break;
        case GlassLevel.floating:
          shadows = const [
            BoxShadow(
              color: AppColors.shadowFloating, // rgba(0, 0, 0, 0.28)
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ];
          break;
        case GlassLevel.surface:
          shadows = const [
            BoxShadow(
              color: AppColors.shadowStandard, // rgba(0, 0, 0, 0.18)
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ];
          break;
      }
    }

    final hasSpecular = specularHighlight ?? (level == GlassLevel.floating);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? surfaceColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    if (hasSpecular) {
      content = CustomPaint(
        foregroundPainter: _SpecularTopHighlightPainter(
          borderRadius: borderRadius,
          highlightColor: AppColors.specularHighlight,
        ),
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: blurSigma > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: content,
              )
            : content,
      ),
    );
  }
}

/// Paints a subtle upper-edge reflection (specular highlight) resembling physical illuminated glass edges.
class _SpecularTopHighlightPainter extends CustomPainter {
  final double borderRadius;
  final Color highlightColor;

  const _SpecularTopHighlightPainter({
    required this.borderRadius,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final clipHeight = (borderRadius * 0.9).clamp(6.0, 24.0);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, clipHeight));
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          highlightColor,
          highlightColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, clipHeight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect.deflate(0.5), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpecularTopHighlightPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.highlightColor != highlightColor;
}
