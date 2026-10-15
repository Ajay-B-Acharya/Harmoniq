import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'motion.dart';

/// NEUMORPHIC FLOATING NAVIGATION DOCK
///
/// Monochromatic soft floating dock with 5 destinations:
/// Home, Explore, Library, Search, Profile.
///
/// Features extruded dual shadows, active squircle container,
/// and the signature extruded "1" badge from the reference UI.
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  static const List<String> _labels = [
    'Home',
    'Explore',
    'Library',
    'Search',
    'Profile',
  ];

  static const List<IconData> _icons = [
    Icons.home_outlined,
    Icons.credit_card_outlined,
    Icons.bar_chart_outlined,
    Icons.notifications_none_rounded,
    Icons.person_outline_rounded,
  ];

  static const List<IconData> _selectedIcons = [
    Icons.home_rounded,
    Icons.credit_card_rounded,
    Icons.bar_chart_rounded,
    Icons.notifications_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dockBg = isDark ? AppDarkColors.dockSurface : AppColors.dockSurface;
    final shadowLight =
        isDark ? AppDarkColors.lightShadow : AppColors.lightShadow;
    final shadowDark =
        isDark ? AppDarkColors.darkShadow : AppColors.darkShadow;

    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: dockBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: shadowLight.withValues(alpha: isDark ? 0.90 : 0.95),
                  offset: const Offset(-6, -6),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: shadowDark.withValues(alpha: isDark ? 0.85 : 0.65),
                  offset: const Offset(6, 6),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_labels.length, (index) {
                final selected = index == currentIndex;
                return Expanded(
                  child: Semantics(
                    label: _labels[index],
                    selected: selected,
                    button: true,
                    excludeSemantics: true,
                    onTap: () => onTap(index),
                    child: Pressable(
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: motionDuration(context, 180),
                        curve: Curves.easeOutCubic,
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          minWidth: 48,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? (isDark
                                  ? AppDarkColors.background
                                  : AppColors.background)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: shadowLight.withValues(
                                        alpha: isDark ? 0.90 : 0.95),
                                    offset: const Offset(-2, -2),
                                    blurRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: shadowDark.withValues(
                                        alpha: isDark ? 0.85 : 0.60),
                                    offset: const Offset(2, 2),
                                    blurRadius: 5,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  selected
                                      ? _selectedIcons[index]
                                      : _icons[index],
                                  size: 22,
                                  color: selected
                                      ? AppColors.coral
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _labels[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                            // Signature extruded notification badge "1" (from reference image)
                            if (index == 3)
                              Positioned(
                                top: -2,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        offset: const Offset(-1, -1),
                                        blurRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: AppColors.darkShadow.withValues(alpha: 0.6),
                                        offset: const Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '1',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.coral,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
