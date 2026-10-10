import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';
import 'album_art.dart';
import 'mini_player.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onMoreTap;

  const SongTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    this.isActive = false,
    required this.onTap,
    required this.onFavoriteTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.42)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Material(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: AlbumArt(
              gradientId: song.gradientId,
              size: 48,
              borderRadius: 12,
              showShadow: false,
              imageUrl: song.albumArtUrl,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.accentLight
                          : AppColors.textPrimary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isActive && isPlaying) ...[
                  const SizedBox(width: 6),
                  const MiniEqualizerBars(
                    isPlaying: true,
                    color: AppColors.accent,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              song.album.isNotEmpty && song.album != 'YouTube'
                  ? "${song.artist} · ${song.album}"
                  : song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? AppColors.accentLight.withValues(alpha: 0.75)
                    : AppColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: song.isFavorite ? 'Remove favorite' : 'Add favorite',
                  icon: Icon(
                    song.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: song.isFavorite
                        ? AppColors.heartColor
                        : AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: onFavoriteTap,
                  splashRadius: 20,
                ),
                if (onMoreTap != null)
                  IconButton(
                    tooltip: 'Song options',
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: onMoreTap,
                    splashRadius: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
