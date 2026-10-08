import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lightweight, GPU-friendly startup animation widget.
class OpeningAnimationView extends StatefulWidget {
  final VoidCallback onFinished;

  const OpeningAnimationView({super.key, required this.onFinished});

  @override
  State<OpeningAnimationView> createState() => _OpeningAnimationViewState();
}

class _OpeningAnimationViewState extends State<OpeningAnimationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _fallbackTimer;
  bool _finished = false;

  void _finishImmediately() {
    if (!_finished) {
      _finished = true;
      _fallbackTimer?.cancel();
      widget.onFinished();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_finished) {
        _finishImmediately();
      }
    });

    // Device-compatibility guarantee: Fallback timer ensures that even if
    // system Tickers are paused/throttled by permission dialogs or power-saving
    // mode on other devices, the app ALWAYS advances to the main screen.
    _fallbackTimer = Timer(const Duration(milliseconds: 2300), () {
      if (mounted) {
        _finishImmediately();
      }
    });

    // Start playback after first frame to ensure smooth GPU sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _finishImmediately();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const ColoredBox(color: AppColors.background);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0.0 -> 1.0 (corresponds to 0 -> 1900ms)
        // Millisecond mapping:
        // 0.2s = 200 / 1900 = 0.105
        // 0.7s = 700 / 1900 = 0.368
        // 1.1s = 1100 / 1900 = 0.579
        // 1.4s = 1400 / 1900 = 0.737
        // 1.8s = 1800 / 1900 = 0.947

        // 1. Waveform opacity: appears at 0.2s (0.105), fades out when emblem resolves (0.7s - 1.0s)
        final waveOpacity = t < 0.105
            ? 0.0
            : (t < 0.20
                ? ((t - 0.105) / 0.095).clamp(0.0, 1.0)
                : (t < 0.55
                    ? 1.0
                    : (1.0 - ((t - 0.55) / 0.15)).clamp(0.0, 1.0)));

        // 2. Wave compression factor (0.2s - 0.7s: 0.105 -> 0.368): moves and compresses toward center
        final waveCompression = t < 0.105
            ? 0.0
            : ((t - 0.105) / 0.263).clamp(0.0, 1.0);

        // 3. Emblem reveal: 0.7s - 1.1s (0.368 -> 0.579)
        final emblemProgress = t < 0.368
            ? 0.0
            : ((t - 0.368) / 0.211).clamp(0.0, 1.0);
        final emblemOpacity = Curves.easeOutCubic.transform(emblemProgress);
        final emblemScale = 0.85 + (0.15 * Curves.easeOutBack.transform(emblemProgress));

        // 4. HARMONIQ wordmark: 1.1s - 1.4s (0.579 -> 0.737)
        final wordmarkProgress = t < 0.579
            ? 0.0
            : ((t - 0.579) / 0.158).clamp(0.0, 1.0);
        final wordmarkOpacity = Curves.easeOut.transform(wordmarkProgress);
        final wordmarkOffsetY = 10.0 * (1.0 - wordmarkOpacity);

        // 5. Fade out at 1.8s - 2.0s (0.947 -> 1.0) for smooth home page transition
        final exitFade = t < 0.947
            ? 1.0
            : (1.0 - ((t - 0.947) / 0.053)).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _finishImmediately,
            child: Opacity(
              opacity: exitFade,
              child: Stack(
                fit: StackFit.expand,
                children: [
                // Waveform layer (center)
                if (waveOpacity > 0.01)
                  Center(
                    child: Opacity(
                      opacity: waveOpacity,
                      child: CustomPaint(
                        size: const Size(260, 60),
                        painter: _AudioWaveformPainter(
                          compression: waveCompression,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),

                // Emblem + Wordmark layer (revealed from center)
                if (emblemProgress > 0.01)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: emblemOpacity,
                          child: Transform.scale(
                            scale: emblemScale,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: AppColors.backgroundSecondary,
                                border: Border.all(
                                  color: AppColors.surfaceBorder,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.18),
                                    blurRadius: 18,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const HarmoniqEmblemSilhouette(size: 72),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // HARMONIQ wordmark
                        Opacity(
                          opacity: wordmarkOpacity,
                          child: Transform.translate(
                            offset: Offset(0, wordmarkOffsetY),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'HARMONIQ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 6.0,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'YOUR MUSIC. YOUR RHYTHM.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.2,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }
}

/// Thin red audio waveform that subtly moves and compresses toward center
class _AudioWaveformPainter extends CustomPainter {
  final double compression; // 0.0 -> 1.0
  final Color color;

  _AudioWaveformPainter({required this.compression, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    // Number of bars
    const count = 21;
    final spacing = w / (count + 1);

    // As compression advances toward 1.0, bars compress towards center and damp amplitude
    final spread = (1.0 - (compression * 0.72)).clamp(0.2, 1.0);
    final centerIndex = count ~/ 2;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    for (int i = 0; i < count; i++) {
      final distFromCenter = (i - centerIndex).abs();
      // Wave motion pulse based on index
      final phase = (i / count) * math.pi * 2;
      final rawHeight = (math.sin(phase - (compression * math.pi * 3)).abs() * 0.7 + 0.3);
      final heightFactor = (1.0 - (distFromCenter / (count / 2) * 0.6)).clamp(0.2, 1.0);
      final barHeight = (h * 0.75) * rawHeight * heightFactor * (1.0 - (compression * 0.45));

      final x = (w / 2) + ((i - centerIndex) * spacing * spread);
      canvas.drawLine(
        Offset(x, midY - (barHeight / 2)),
        Offset(x, midY + (barHeight / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AudioWaveformPainter oldDelegate) =>
      oldDelegate.compression != compression || oldDelegate.color != color;
}

/// Clean vector Harmoniq "H" musical emblem
class HarmoniqEmblemSilhouette extends StatelessWidget {
  final double size;

  const HarmoniqEmblemSilhouette({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SilhouettePainter(),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Left vertical stem (red)
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.20, h * 0.12, w * 0.33, h * 0.60),
      Radius.circular(w * 0.05),
    );
    final leftShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.accent, AppColors.accentDark],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(leftRect, Paint()..shader = leftShader);

    // Left note bulb (red)
    final bulbCenter = Offset(w * 0.22, h * 0.72);
    final bulbRadius = w * 0.13;
    final bulbShader = const RadialGradient(
      colors: [AppColors.accent, AppColors.accentDark],
    ).createShader(Rect.fromCircle(center: bulbCenter, radius: bulbRadius));
    canvas.drawCircle(bulbCenter, bulbRadius, Paint()..shader = bulbShader);

    // Left stem connection
    final stemPath = Path()
      ..moveTo(w * 0.25, h * 0.52)
      ..lineTo(w * 0.33, h * 0.52)
      ..lineTo(w * 0.27, h * 0.74)
      ..lineTo(w * 0.19, h * 0.74)
      ..close();
    canvas.drawPath(stemPath, Paint()..shader = bulbShader);

    // Right vertical stem (red + dark red)
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.67, h * 0.12, w * 0.80, h * 0.80),
      Radius.circular(w * 0.05),
    );
    final rightShader = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [AppColors.accent, AppColors.accentDark],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(rightRect, Paint()..shader = rightShader);

    // Right swept curve
    final rightSweep = Path()
      ..moveTo(w * 0.67, h * 0.20)
      ..cubicTo(w * 0.76, h * 0.26, w * 0.80, h * 0.36, w * 0.80, h * 0.46)
      ..lineTo(w * 0.80, h * 0.74)
      ..cubicTo(w * 0.80, h * 0.82, w * 0.72, h * 0.82, w * 0.67, h * 0.76)
      ..close();
    canvas.drawPath(
      rightSweep,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    // Metallic silver connecting audio curve
    final wavePath = Path()
      ..moveTo(w * 0.26, h * 0.62)
      ..cubicTo(w * 0.35, h * 0.48, w * 0.42, h * 0.42, w * 0.52, h * 0.45)
      ..cubicTo(w * 0.62, h * 0.48, w * 0.70, h * 0.38, w * 0.76, h * 0.26)
      ..cubicTo(w * 0.72, h * 0.38, w * 0.62, h * 0.54, w * 0.52, h * 0.52)
      ..cubicTo(w * 0.40, h * 0.50, w * 0.32, h * 0.60, w * 0.26, h * 0.62)
      ..close();

    final waveShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [AppColors.accent, AppColors.metallicAccent, AppColors.accent],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(wavePath, Paint()..shader = waveShader);

    // Metallic highlight line
    final linePath = Path()
      ..moveTo(w * 0.29, h * 0.56)
      ..cubicTo(w * 0.38, h * 0.46, w * 0.46, h * 0.43, w * 0.53, h * 0.46)
      ..cubicTo(w * 0.61, h * 0.48, w * 0.68, h * 0.39, w * 0.74, h * 0.30);

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.metallicAccent.withValues(alpha: 0.6)
        ..strokeWidth = w * 0.022
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
