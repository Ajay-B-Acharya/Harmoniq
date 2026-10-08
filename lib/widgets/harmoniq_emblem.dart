import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Harmoniq logo emblem rendered with vector paths to seamlessly complement
/// the dark + red + metallic silver theme without purple/neon gradients.
class HarmoniqEmblem extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color accentColor;
  final Color silverColor;

  const HarmoniqEmblem({
    super.key,
    this.size = 80,
    this.primaryColor = AppColors.accent,
    this.accentColor = AppColors.accentDark,
    this.silverColor = AppColors.metallicAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HarmoniqEmblemPainter(
          primaryColor: primaryColor,
          accentColor: accentColor,
          silverColor: silverColor,
        ),
      ),
    );
  }
}

class _HarmoniqEmblemPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final Color silverColor;

  _HarmoniqEmblemPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.silverColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw the "H" musical emblem matching Harmoniq's silhouette

    // Red gradient for left pillar
    final leftShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [primaryColor, accentColor],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final paintLeft = Paint()
      ..shader = leftShader
      ..style = PaintingStyle.fill;

    // Left rounded bar
    final rrectLeft = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.22, h * 0.10, w * 0.34, h * 0.60),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(rrectLeft, paintLeft);

    // Left note bulb (musical note head at bottom-left)
    final bulbCenter = Offset(w * 0.20, h * 0.72);
    final bulbRadius = w * 0.13;
    final bulbShader = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      radius: 0.8,
      colors: [primaryColor, accentColor],
    ).createShader(Rect.fromCircle(center: bulbCenter, radius: bulbRadius));
    canvas.drawCircle(bulbCenter, bulbRadius, Paint()..shader = bulbShader);

    // Stem connecting bulb to left bar
    final stemPath = Path()
      ..moveTo(w * 0.26, h * 0.52)
      ..lineTo(w * 0.34, h * 0.52)
      ..lineTo(w * 0.26, h * 0.76)
      ..lineTo(w * 0.18, h * 0.76)
      ..close();
    canvas.drawPath(stemPath, Paint()..shader = bulbShader);

    // Right pillar
    final rightShader = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [primaryColor, accentColor],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    final rrectRight = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.66, h * 0.10, w * 0.78, h * 0.78),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(rrectRight, Paint()..shader = rightShader);

    // Right swept ribbon curve
    final rightRibbon = Path()
      ..moveTo(w * 0.66, h * 0.22)
      ..cubicTo(w * 0.74, h * 0.28, w * 0.78, h * 0.38, w * 0.78, h * 0.48)
      ..lineTo(w * 0.78, h * 0.72)
      ..cubicTo(w * 0.78, h * 0.80, w * 0.70, h * 0.80, w * 0.66, h * 0.74)
      ..close();
    canvas.drawPath(
      rightRibbon,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    // Flowing sonic wave / crossbar connecting left note to right stem
    final wavePath = Path()
      ..moveTo(w * 0.24, h * 0.64)
      ..cubicTo(w * 0.32, h * 0.50, w * 0.38, h * 0.42, w * 0.50, h * 0.45)
      ..cubicTo(w * 0.62, h * 0.48, w * 0.70, h * 0.38, w * 0.76, h * 0.28)
      ..cubicTo(w * 0.72, h * 0.38, w * 0.62, h * 0.54, w * 0.50, h * 0.52)
      ..cubicTo(w * 0.38, h * 0.50, w * 0.30, h * 0.62, w * 0.24, h * 0.64)
      ..close();

    final waveShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [primaryColor, silverColor, primaryColor],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = waveShader
        ..style = PaintingStyle.fill,
    );

    // Subtle metallic highlight line across wave
    final highlightPath = Path()
      ..moveTo(w * 0.28, h * 0.58)
      ..cubicTo(w * 0.36, h * 0.46, w * 0.44, h * 0.43, w * 0.52, h * 0.46)
      ..cubicTo(w * 0.60, h * 0.48, w * 0.68, h * 0.40, w * 0.74, h * 0.32);

    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = silverColor.withValues(alpha: 0.5)
        ..strokeWidth = w * 0.02
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HarmoniqEmblemPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.silverColor != silverColor;
}
