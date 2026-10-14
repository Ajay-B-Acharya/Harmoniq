import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// SPATIAL UI — 7.B AVATAR HALO
///
/// A restrained cyan-to-blue halo around user avatars.
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
            AppColors.primaryCyan,
            AppColors.blue,
            AppColors.lightCyan,
            AppColors.primaryCyan,
          ],
          stops: [0.0, 0.42, 0.76, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowActiveCyan,
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
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
