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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isActive
              ? (isDark
                  ? AppDarkColors.dockActiveSurface
                  : AppColors.glassSelected)
              : Colors.transparent,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: (isDark
                            ? AppDarkColors.lightShadow
                            : AppColors.lightShadow)
                        .withValues(alpha: isDark ? 0.7 : 0.8),
                    offset: const Offset(-1, -1),
                    blurRadius: 3,
                  ),
                  BoxShadow(
                    color: (isDark
                            ? AppDarkColors.darkShadow
                            : AppColors.darkShadow)
                        .withValues(alpha: isDark ? 0.85 : 0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ]
              : null,
          border: Border.all(
            color: isActive
                ? AppColors.coral.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
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
                          ? AppColors.coral
                          : AppColors.textPrimaryOf(context),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isActive && isPlaying) ...[
                  const SizedBox(width: 6),
                  const MiniEqualizerBars(
                    isPlaying: true,
                    color: AppColors.coral,
                  ),
                ],
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    song.album.isNotEmpty && song.album != 'YouTube'
                        ? "${song.artist} · ${song.album}"
                        : song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? AppColors.coralLight
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
                if (song.downloadQuality != null || song.source == SongSource.local) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.black.withValues(alpha: 0.10),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      song.downloadQuality != null
                          ? '${song.downloadQuality!.toUpperCase()} MP3'
                          : 'OFFLINE',
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
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
                        : AppColors.textSecondaryOf(context),
                    size: 20,
                  ),
                  onPressed: onFavoriteTap,
                  splashRadius: 20,
                ),
                if (onMoreTap != null)
                  IconButton(
                    tooltip: 'Song options',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark
                          ? AppDarkColors.textSecondary
                          : AppColors.textSecondary,
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
