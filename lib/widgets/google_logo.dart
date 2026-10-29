import 'package:flutter/material.dart';

/// Pixel-perfect vector representation of the official 4-color Google 'G' logo.
/// Dependency-free and scales smoothly to any resolution.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({
    super.key,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Standard Google logo coordinate space is 24x24
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Blue quadrant (#4285F4)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(23.74, 12.27)
      ..cubicTo(23.74, 11.57, 23.68, 10.87, 23.55, 10.2)
      ..lineTo(12.0, 10.2)
      ..lineTo(12.0, 14.71)
      ..lineTo(18.6, 14.71)
      ..cubicTo(18.31, 16.23, 17.46, 17.53, 16.2, 18.39)
      ..lineTo(16.2, 21.44)
      ..lineTo(20.08, 21.44)
      ..cubicTo(22.35, 19.35, 23.74, 16.27, 23.74, 12.27)
      ..close();
    canvas.drawPath(bluePath, paint);

    // 2. Green quadrant (#34A853)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.95, 22.92, 19.93, 21.09)
      ..lineTo(16.05, 18.04)
      ..cubicTo(14.97, 18.76, 13.6, 19.2, 12.0, 19.2)
      ..cubicTo(8.88, 19.2, 6.22, 17.1, 5.27, 14.27)
      ..lineTo(1.25, 14.27)
      ..lineTo(1.25, 17.42)
      ..cubicTo(3.26, 21.36, 7.33, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, paint);

    // 3. Yellow quadrant (#FBBC05)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.27, 14.27)
      ..cubicTo(5.02, 13.55, 4.89, 12.78, 4.89, 12.0)
      ..cubicTo(4.89, 11.22, 5.02, 10.45, 5.27, 9.73)
      ..lineTo(5.27, 6.58)
      ..lineTo(1.25, 6.58)
      ..cubicTo(0.45, 8.16, 0.0, 9.94, 0.0, 12.0)
      ..cubicTo(0.0, 14.06, 0.45, 15.84, 1.25, 17.42)
      ..lineTo(5.27, 14.27)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // 4. Red quadrant (#EA4335)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0, 4.75)
      ..cubicTo(13.77, 4.75, 15.35, 5.36, 16.6, 6.55)
      ..lineTo(20.02, 3.13)
      ..cubicTo(17.95, 1.19, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.33, 0.0, 3.26, 2.64, 1.25, 6.58)
      ..lineTo(5.27, 9.73)
      ..cubicTo(6.22, 6.9, 8.88, 4.75, 12.0, 4.75)
      ..close();
    canvas.drawPath(redPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
