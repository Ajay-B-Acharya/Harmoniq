import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A rounded card with optional glassmorphism blur.
///
/// **Performance note:** Pass [blurSigma] = 0 (or leave it unset and set
/// [noBlur] = true) to skip the [BackdropFilter] entirely and render a plain
/// opaque surface. Do this for any card that sits on top of moving content
/// (scrolling lists, playing animations) to avoid expensive per-frame GPU
/// blur recomposition.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  /// Set to 0 to disable BackdropFilter completely (best for scrolling content).
  final double blurSigma;

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
    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.glassBackground) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    final shadows = <BoxShadow>[
      BoxShadow(
        color: AppColors.glassShadow,
        blurRadius: 14,
        spreadRadius: -2,
        offset: const Offset(0, 4),
      ),
      if (glowColor != null)
        BoxShadow(
          color: glowColor!.withValues(alpha: 0.28),
          blurRadius: 16,
          spreadRadius: 1,
        ),
    ];

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
                child: inner,
              )
            : inner,
      ),
    );
  }
}
