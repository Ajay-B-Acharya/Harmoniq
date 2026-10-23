import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Neumorphic soft canvas background providing uniform monochromatic surface
/// and subtle top-left ambient illumination for soft 3D plastic extrusion.
class SpatialNebulaBackground extends StatelessWidget {
  final Widget child;

  const SpatialNebulaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _NeumorphicCanvasPainter(isDark: isDark),
        child: child,
      ),
    );
  }
}

@Deprecated('Use SpatialNebulaBackground instead.')
class SpatialBackground extends SpatialNebulaBackground {
  const SpatialBackground({super.key, required super.child});
}

class _NeumorphicCanvasPainter extends CustomPainter {
  final bool isDark;
  const _NeumorphicCanvasPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = isDark
        ? const [
            Color(0xFF080808),
            AppDarkColors.background,
            Color(0xFF000000),
          ]
        : const [
            Color(0xFFFFFDF8),
            AppColors.background,
            Color(0xFFEFE6D6),
          ];

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _NeumorphicCanvasPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
