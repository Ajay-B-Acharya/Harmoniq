import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A quiet, layered canvas that keeps content readable while adding depth.
class SpatialBackground extends StatelessWidget {
  final Widget child;

  const SpatialBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111922), AppColors.background, Color(0xFF090D12)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.75, -0.9),
                    radius: 1.15,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.055),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
