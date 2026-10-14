import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'motion.dart';

/// SPATIAL UI — 8. FLOATING NAVIGATION DOCK
///
/// Suspended transparent glass dock with 5 destinations:
/// Home, Explore, Library, Search, Profile.
///
/// Cyan-selected glass dock with a blurred background and muted silver inactive items.
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowFloating,
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: CustomPaint(
                  foregroundPainter: const _DockSpecularHighlightPainter(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.dockSurface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.dockBorder,
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
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
                                duration: motionDuration(context, 200),
                                curve: Curves.easeOutCubic,
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                  minWidth: 48,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.dockActiveSurface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: selected
                                      ? Border.all(
                                          color: AppColors.dockActiveBorder,
                                          width: 1.0,
                                        )
                                      : null,
                                  boxShadow: selected
                                      ? const [
                                          BoxShadow(
                                            color: AppColors.dockActiveGlow,
                                            blurRadius: 14,
                                            offset: Offset(0, 1),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          selected
                                              ? _selectedIcons[index]
                                              : _icons[index],
                                          size: 21,
                                          color: selected
                                              ? AppColors
                                                    .textPrimary // Near-white
                                              : AppColors.dockInactive, // rgba(248, 250, 252, 0.60)
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
                                                : AppColors.dockInactive,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Subtle sparkle accent on active profile
                                    if (index == 4 && selected)
                                      Positioned(
                                        top: -2,
                                        right: 6,
                                        child: Icon(
                                          Icons.auto_awesome,
                                          size: 11,
                                          color: AppColors.lightCyan.withValues(
                                            alpha: 0.9,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _DockSpecularHighlightPainter extends CustomPainter {
  const _DockSpecularHighlightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    const radius = 28.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, 16));
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.specularHighlight, // rgba(255, 255, 255, 0.22)
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 16))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect.deflate(0.5), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
