import 'package:flutter/material.dart';

import '../models/youtube_video.dart';
import '../theme/app_colors.dart';
import 'motion.dart';

class YoutubeCard extends StatelessWidget {
  final YoutubeVideo video;
  final VoidCallback onTap;

  const YoutubeCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  String _formatDuration(Duration d) {
    if (d <= Duration.zero) return '';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.cardSurface : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppDarkColors.cardBorder : Colors.transparent,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark
                        ? AppDarkColors.lightShadow
                        : AppColors.lightShadow)
                    .withValues(alpha: isDark ? 0.70 : 0.95),
                offset: const Offset(-3, -3),
                blurRadius: 7,
              ),
              BoxShadow(
                color: (isDark
                        ? AppDarkColors.darkShadow
                        : AppColors.darkShadow)
                    .withValues(alpha: isDark ? 0.85 : 0.65),
                offset: const Offset(3, 3),
                blurRadius: 7,
              ),
            ],
          ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(
                      color: AppColors.surfaceHigh,
                      child: Icon(
                        Icons.music_note_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    if (video.thumbnailUrl.isNotEmpty)
                      Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 174,
                        errorBuilder: (_, error, stack) =>
                            const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppDarkColors.textSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (video.duration > Duration.zero) ...[
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(video.duration),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppDarkColors.textSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppDarkColors.cardSurface
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (isDark
                            ? AppDarkColors.lightShadow
                            : Colors.white)
                        .withValues(alpha: isDark ? 0.70 : 0.95),
                    offset: const Offset(-1.5, -1.5),
                    blurRadius: 3,
                  ),
                  BoxShadow(
                    color: (isDark
                            ? AppDarkColors.darkShadow
                            : AppColors.darkShadow)
                        .withValues(alpha: isDark ? 0.85 : 0.65),
                    offset: const Offset(1.5, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.coral,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
