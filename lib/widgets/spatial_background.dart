import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// SPATIAL UI — 1. BACKGROUND: DARK NEBULA ATMOSPHERE
///
/// Deep, almost-black spatial environment with subtle blue-violet atmospheric lighting.
/// Uses oversized, smoothly blended radial gradients positioned in selected regions
/// while keeping the center and content regions sufficiently dark for high contrast.
class SpatialNebulaBackground extends StatelessWidget {
  final Widget child;

  const SpatialNebulaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: const _NebulaAtmospherePainter(),
        child: child,
      ),
    );
  }
}

@Deprecated('Use SpatialNebulaBackground instead.')
class SpatialBackground extends SpatialNebulaBackground {
  const SpatialBackground({super.key, required super.child});
}

class _NebulaAtmospherePainter extends CustomPainter {
  const _NebulaAtmospherePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base background: near-black base with faint vertical depth (#090B14 to #05060A)
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.backgroundSecondary, // #090B14
          AppColors.background, // #05060A
          AppColors.background, // #05060A
        ],
        stops: [0.0, 0.35, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    if (size.width <= 0 || size.height <= 0) return;

    // 1. Upper-right restrained violet atmospheric light
    // Suggested: rgba(124, 58, 237, 0.10)
    final violetRadius = size.width * 1.15;
    final violetCenter = Offset(size.width * 0.90, size.height * 0.08);
    final violetPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.nebulaViolet, // rgba(124, 58, 237, 0.10)
          AppColors.nebulaViolet.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(
        Rect.fromCircle(center: violetCenter, radius: violetRadius),
      );
    canvas.drawCircle(violetCenter, violetRadius, violetPaint);

    // 2. Upper-left cool blue atmospheric light with gentle cyan blend
    // Suggested: Blue rgba(59, 130, 246, 0.07), Cyan rgba(6, 182, 212, 0.035)
    final blueRadius = size.width * 1.05;
    final blueCenter = Offset(size.width * 0.10, size.height * 0.22);
    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.nebulaBlue, // rgba(59, 130, 246, 0.07)
          AppColors.nebulaCyan, // rgba(6, 182, 212, 0.035)
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(center: blueCenter, radius: blueRadius),
      );
    canvas.drawCircle(blueCenter, blueRadius, bluePaint);

    // 3. Mid-right restrained magenta / deep blue-violet tone
    // Suggested: Magenta rgba(236, 72, 153, 0.04)
    final magentaRadius = size.width * 0.85;
    final magentaCenter = Offset(size.width * 0.98, size.height * 0.60);
    final magentaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.nebulaMagenta, // rgba(236, 72, 153, 0.04)
          AppColors.deepBlueViolet.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(
        Rect.fromCircle(center: magentaCenter, radius: magentaRadius),
      );
    canvas.drawCircle(magentaCenter, magentaRadius, magentaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
