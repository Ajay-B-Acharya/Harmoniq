import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'motion.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  static const List<String> _labels = ['Home', 'Search', 'Music', 'Library'];
  static const List<IconData> _icons = [
    Icons.home_outlined,
    Icons.search_rounded,
    Icons.graphic_eq_rounded,
    Icons.library_music_outlined,
  ];
  static const List<IconData> _selectedIcons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.graphic_eq_rounded,
    Icons.library_music_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.07),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: List.generate(4, (index) {
                final selected = index == currentIndex;
                final isMusicCenter = index == 2;

                return Expanded(
                  child: Semantics(
                    label: _labels[index],
                    selected: selected,
                    button: true,
                    excludeSemantics: true,
                    onTap: () => onTap(index),
                    child: Pressable(
                      onTap: () => onTap(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: motionDuration(context),
                              curve: Curves.easeOutCubic,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMusicCenter ? 18 : 16,
                                vertical: isMusicCenter ? 5 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: isMusicCenter
                                    ? (selected
                                          ? AppColors.accent.withValues(
                                              alpha: 0.22,
                                            )
                                          : AppColors.surfaceHigh)
                                    : (selected
                                          ? AppColors.accent.withValues(
                                              alpha: 0.14,
                                            )
                                          : Colors.transparent),
                                borderRadius: BorderRadius.circular(10),
                                border: isMusicCenter
                                    ? Border.all(
                                        color: selected
                                            ? AppColors.accent.withValues(
                                                alpha: 0.6,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.12,
                                              ),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                selected
                                    ? _selectedIcons[index]
                                    : _icons[index],
                                size: isMusicCenter ? 24 : 22,
                                color: selected
                                    ? AppColors.accent
                                    : (isMusicCenter
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _labels[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
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
