import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// SPATIAL UI — 7.B AVATAR HALO
///
/// A restrained cyan-to-violet-to-pink gradient halo around user avatars.
class AvatarHalo extends StatelessWidget {
  final double size;
  final Widget child;
  final double borderWidth;
  final VoidCallback? onTap;

  const AvatarHalo({
    super.key,
    this.size = 38,
    this.borderWidth = 1.5,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            AppColors.cyan,
            AppColors.primaryViolet,
            AppColors.neonPink,
            AppColors.lightCyan,
            AppColors.cyan,
          ],
          stops: [0.0, 0.35, 0.65, 0.88, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1FA855F7), // Restrained violet ambient glow
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundSecondary,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: child,
      ),
    );

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
