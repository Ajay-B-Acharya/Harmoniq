import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Elevation hierarchy for Neumorphic surfaces:
/// - Level 2 (surface): standard extruded card with soft dual shadows.
/// - Level 3 (floating): elevated extruded card with deeper dual shadows.
/// - Level 4 (active): active card with subtle coral accent edge/glow.
enum GlassLevel { surface, floating, active }

enum GlassTint { neutral, cyan, blue, selected }

/// Neumorphic extruded card emerging directly out of the monochromatic background
/// with dual outer shadows (white highlight at top-left, soft slate shadow at bottom-right).
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
    this.borderRadius = 18,
    this.blurSigma = 0,
    this.level = GlassLevel.surface,
    this.tint = GlassTint.neutral,
    this.specularHighlight,
    this.color,
    this.gradient,
    this.borderColor,
    this.borderWidth = 0.8,
    this.glowColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDarkColors.background : AppColors.background;
    final shadowLight =
        isDark ? AppDarkColors.lightShadow : AppColors.lightShadow;
    final shadowDark =
        isDark ? AppDarkColors.darkShadow : AppColors.darkShadow;

    // 1. Resolve surface color (monochromatic plastic extrusion)
    final Color surfaceColor;
    if (color != null) {
      surfaceColor = color!;
    } else {
      switch (level) {
        case GlassLevel.active:
          surfaceColor = isDark
              ? AppDarkColors.dockActiveSurface
              : AppColors.glassSelected;
          break;
        case GlassLevel.floating:
          surfaceColor = bg;
          break;
        case GlassLevel.surface:
          surfaceColor = tint == GlassTint.selected
              ? (isDark
                  ? AppDarkColors.dockActiveSurface
                  : AppColors.glassSelected)
              : bg;
          break;
      }
    }

    // 2. Resolve border (subtle light highlight for crisp bevel)
    final Color effectiveBorderColor;
    if (borderColor != null) {
      effectiveBorderColor = borderColor!;
    } else {
      switch (level) {
        case GlassLevel.active:
          effectiveBorderColor = AppColors.borderActiveCyan;
          break;
        case GlassLevel.floating:
          effectiveBorderColor = Colors.white.withValues(alpha: isDark ? 0.2 : 0.5);
          break;
        case GlassLevel.surface:
          effectiveBorderColor = Colors.white.withValues(alpha: isDark ? 0.15 : 0.35);
          break;
      }
    }

    // 3. Resolve dual Neumorphic shadows
    final double depth;
    switch (level) {
      case GlassLevel.floating:
        depth = 6.0;
        break;
      case GlassLevel.active:
      case GlassLevel.surface:
        depth = 4.5;
        break;
    }

    final List<BoxShadow> shadows;
    if (glowColor != null) {
      shadows = [
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.90 : 0.95),
          offset: Offset(-depth, -depth),
          blurRadius: depth * 2.2,
          spreadRadius: 0.5,
        ),
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.85 : 0.65),
          offset: Offset(depth, depth),
          blurRadius: depth * 2.2,
          spreadRadius: 0.5,
        ),
        BoxShadow(
          color: glowColor!.withValues(alpha: 0.25),
          blurRadius: 14,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (level == GlassLevel.active) {
      shadows = [
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.90 : 0.95),
          offset: Offset(-depth, -depth),
          blurRadius: depth * 2.2,
          spreadRadius: 0.5,
        ),
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.85 : 0.65),
          offset: Offset(depth, depth),
          blurRadius: depth * 2.2,
          spreadRadius: 0.5,
        ),
        BoxShadow(
          color: AppColors.coral.withValues(alpha: 0.18),
          blurRadius: 12,
          offset: const Offset(0, 1),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.90 : 0.95),
          offset: Offset(-depth, -depth),
          blurRadius: depth * 2.2,
          spreadRadius: 0.5,
        ),
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.85 : 0.65),
          offset: Offset(depth, depth),
          blurRadius: depth * 2.2,
          spreadRadius: 0.5,
        ),
      ];
    }

    final hasSpecular = specularHighlight ?? (level == GlassLevel.floating);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? surfaceColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorderColor, width: borderWidth),
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

/// Paints a subtle upper-edge reflection resembling soft plastic specular highlights.
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
        colors: [highlightColor, highlightColor.withValues(alpha: 0.0)],
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
