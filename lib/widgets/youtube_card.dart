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
  Widget build(BuildContext context) => RepaintBoundary(
    child: Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33050914),
              blurRadius: 10,
              offset: Offset(0, 3),
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: AppColors.textPrimary,
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (video.duration > Duration.zero) ...[
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(video.duration),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
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
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
