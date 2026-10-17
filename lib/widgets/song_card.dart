import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';
import 'album_art.dart';
import 'motion.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final double width;

  const SongCard({
    super.key,
    required this.song,
    required this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: SizedBox(
          width: width,
          child: Pressable(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final artSize = constraints.maxHeight.isFinite
                          ? constraints.maxHeight.clamp(0.0, width)
                          : width;
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      return SizedBox(
                        width: artSize,
                        height: artSize,
                        child: Stack(
                          children: [
                            AlbumArt(
                              gradientId: song.gradientId,
                              size: artSize,
                              borderRadius: 18,
                              imageUrl: song.albumArtUrl,
                              showShadow: false,
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppDarkColors.cardSurface
                                      : AppColors.background,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark
                                              ? AppDarkColors.lightShadow
                                              : Colors.white)
                                          .withValues(
                                              alpha: isDark ? 0.70 : 0.95),
                                      offset: const Offset(-2, -2),
                                      blurRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: (isDark
                                              ? AppDarkColors.darkShadow
                                              : AppColors.darkShadow)
                                          .withValues(
                                              alpha: isDark ? 0.85 : 0.70),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.coral,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppDarkColors.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppDarkColors.textSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
