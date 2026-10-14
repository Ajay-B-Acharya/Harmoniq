import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundSecondary,
            AppColors.background,
            AppColors.background,
          ],
          stops: [0, 0.48, 1],
        ).createShader(rect),
    );

    if (size.isEmpty) return;

    _paintCloud(
      canvas,
      center: Offset(size.width * 0.04, size.height * 0.12),
      radius: size.width * 1.25,
      colors: [
        AppColors.nebulaBlue,
        AppColors.nebulaCoolBlue,
        Colors.transparent,
      ],
      stops: const [0, 0.46, 1],
    );
    _paintCloud(
      canvas,
      center: Offset(size.width * 0.93, size.height * 0.18),
      radius: size.width * 1.08,
      colors: [
        AppColors.nebulaCyan,
        AppColors.nebulaCoolBlue.withValues(alpha: 0.035),
        Colors.transparent,
      ],
      stops: const [0, 0.48, 1],
    );
    _paintCloud(
      canvas,
      center: Offset(size.width * 0.44, size.height * 0.50),
      radius: size.width * 1.15,
      colors: [
        AppColors.nebulaCoolBlue.withValues(alpha: 0.045),
        Colors.transparent,
      ],
      stops: const [0, 1],
    );
  }

  void _paintCloud(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required List<Color> colors,
    required List<double> stops,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
        stops: stops,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _NebulaAtmospherePainter oldDelegate) => false;
}
