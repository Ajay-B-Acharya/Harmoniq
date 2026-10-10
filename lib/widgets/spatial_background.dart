import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Layered atmospheric background environment for Harmoniq Spatial UI.
/// Provides deep blue-gray canvas with soft violet and cyan ambient glow layers.
class SpatialBackground extends StatelessWidget {
  final Widget child;

  const SpatialBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Upper-right violet ambient lighting aura
          Positioned(
            top: -100,
            right: -80,
            width: 380,
            height: 380,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryViolet.withValues(alpha: 0.18),
                      AppColors.secondaryPurple.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Lower-left soft cyan ambient lighting aura
          Positioned(
            bottom: 40,
            left: -90,
            width: 340,
            height: 340,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.softCyan.withValues(alpha: 0.13),
                      AppColors.electricBlue.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Center subtle ambient purple depth
          Positioned(
            top: 260,
            left: 30,
            width: 280,
            height: 280,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryPurple.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            ),
          ),

          // Foreground child
          child,
        ],
      ),
    );
  }
}
