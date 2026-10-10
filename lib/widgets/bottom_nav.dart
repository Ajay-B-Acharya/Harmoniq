import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'motion.dart';

/// Compact, low-profile navigation for the five main destinations.
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
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundSecondary,
            border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
          ),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        minWidth: 48,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? _selectedIcons[index] : _icons[index],
                            size: 21,
                            color: selected
                                ? AppColors.accentLight
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
    );
  }
}
