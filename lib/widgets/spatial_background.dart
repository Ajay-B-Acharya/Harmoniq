import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Neumorphic soft canvas background providing uniform monochromatic surface
/// and subtle top-left ambient illumination for soft 3D plastic extrusion.
class SpatialNebulaBackground extends StatelessWidget {
  final Widget child;

  const SpatialNebulaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: const _NeumorphicCanvasPainter(),
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
  const _NeumorphicCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base monochromatic soft canvas
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEFF3F8), // Subtle highlight in top-left
            AppColors.background,
            Color(0xFFE2E7ED), // Subtle shadow depth in bottom-right
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _NeumorphicCanvasPainter oldDelegate) => false;
}
