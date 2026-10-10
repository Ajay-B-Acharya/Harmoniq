import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'motion.dart';

/// Floating Spatial glass navigation dock with 5 destinations:
/// Home, Explore, Library, Search, Profile.
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
    Icons.music_note_outlined,
    Icons.explore_outlined,
    Icons.library_music_outlined,
    Icons.search_rounded,
    Icons.person_outline_rounded,
  ];

  static const List<IconData> _selectedIcons = [
    Icons.music_note_rounded,
    Icons.explore_rounded,
    Icons.library_music_rounded,
    Icons.search_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xCC171D30), // Frosted glass surface
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55050914),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
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
                        duration: motionDuration(context, 200),
                        curve: Curves.easeOutCubic,
                        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primaryViolet.withValues(alpha: 0.32),
                                    AppColors.electricBlue.withValues(alpha: 0.18),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          border: selected
                              ? Border.all(
                                  color: AppColors.primaryViolet.withValues(alpha: 0.65),
                                  width: 1.2,
                                )
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryViolet.withValues(alpha: 0.22),
                                    blurRadius: 10,
                                    spreadRadius: 1,
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
                                  size: 21,
                                  color: selected
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _labels[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                            // Profile sparkle highlight in Screenshot 1
                            if (index == 4 && selected)
                              Positioned(
                                top: -2,
                                right: 6,
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 11,
                                  color: AppColors.softCyan.withValues(alpha: 0.9),
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
