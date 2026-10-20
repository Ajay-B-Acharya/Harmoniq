import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AudioWaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double progress; // 0.0 to 1.0
  final ValueChanged<double>? onSeek;
  final int barCount;
  final double height;

  const AudioWaveformVisualizer({
    super.key,
    required this.isPlaying,
    required this.progress,
    this.onSeek,
    this.barCount = 38,
    this.height = 36,
  });

  @override
  State<AudioWaveformVisualizer> createState() =>
      _AudioWaveformVisualizerState();
}

class _AudioWaveformVisualizerState extends State<AudioWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<double> _baseHeights = [];

  @override
  void initState() {
    super.initState();
    final random = math.Random(42);
    for (int i = 0; i < widget.barCount; i++) {
      // Natural music waveform curve profile (lower at edges, richer in mid)
      final centerFactor = math.sin((i / (widget.barCount - 1)) * math.pi);
      final h = (0.25 + 0.65 * centerFactor) * (0.6 + 0.4 * random.nextDouble());
      _baseHeights.add(h.clamp(0.18, 1.0));
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.isPlaying && !_reduceMotion) {
      if (!_animController.isAnimating) _animController.repeat();
    } else {
      _animController.stop();
    }
  }

  @override
  void didUpdateWidget(AudioWaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      _syncAnimation();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final barWidth = math.max(2.5, (totalWidth / widget.barCount) - 2.5);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              if (widget.onSeek != null && totalWidth > 0) {
                final ratio = (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
                widget.onSeek!(ratio);
              }
            },
            onTapDown: (details) {
              if (widget.onSeek != null && totalWidth > 0) {
                final ratio = (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
                widget.onSeek!(ratio);
              }
            },
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final animPhase = _animController.value * 2 * math.pi;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(widget.barCount, (index) {
                    final fraction = index / (widget.barCount - 1);
                    final isPassed = fraction <= widget.progress;

                    // Dynamic sinusoidal oscillation when playing
                    final dynamicWave = widget.isPlaying
                        ? math.sin(animPhase + (index * 0.45)).abs() * 0.35
                        : 0.0;
                    final heightRatio =
                        (_baseHeights[index] + dynamicWave).clamp(0.15, 1.0);
                    final currentBarHeight = widget.height * heightRatio;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: barWidth,
                      height: currentBarHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(barWidth / 2),
                        gradient: isPassed
                            ? const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.accent,
                                  AppColors.primaryCyan,
                                ],
                              )
                            : null,
                        color: isPassed
                            ? null
                            : AppColors.textMuted.withValues(alpha: 0.28),
                        boxShadow: (isPassed && widget.isPlaying)
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
