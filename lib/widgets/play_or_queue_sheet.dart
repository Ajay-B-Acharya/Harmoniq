import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';
import 'album_art.dart';

/// The user's selection when clicking a song while audio is actively playing.
enum PlayOrQueueAction {
  /// Start playing the clicked track immediately.
  playNow,

  /// Enqueue the clicked track to play right after the current song.
  playNext,
}

/// A neumorphic/glass bottom sheet asking the user whether to play the selected song
/// immediately or queue it to play next after the currently playing song.
class PlayOrQueueSheet extends StatelessWidget {
  final Song song;
  final Song? currentSong;

  const PlayOrQueueSheet({
    super.key,
    required this.song,
    this.currentSong,
  });

  /// Presents the bottom sheet and returns the selected [PlayOrQueueAction], or null if dismissed.
  static Future<PlayOrQueueAction?> show(
    BuildContext context, {
    required Song song,
    Song? currentSong,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<PlayOrQueueAction>(
      context: context,
      backgroundColor:
          isDark ? AppDarkColors.backgroundSecondary : AppColors.sheetSurface,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 580),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (ctx) => PlayOrQueueSheet(
        song: song,
        currentSong: currentSong,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
    final textMuted = isDark ? AppDarkColors.textMuted : AppColors.textMuted;
    final surfaceColor =
        isDark ? AppDarkColors.cardSurface : AppColors.glassSecondary;
    final borderColor =
        isDark ? AppDarkColors.cardBorder : AppColors.borderStandard;
    final accentColor = AppColors.coral;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Currently Playing banner
            if (currentSong != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppDarkColors.surfaceHigh.withValues(alpha: 0.6)
                      : AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Now playing: ${currentSong!.title} · ${currentSong!.artist}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Target song header
            Row(
              children: [
                AlbumArt(
                  gradientId: song.gradientId,
                  imageUrl: song.albumArtUrl,
                  size: 52,
                  borderRadius: 12,
                  showShadow: false,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Option 1: Play Now
            _ActionTile(
              title: 'Play Now',
              subtitle: 'Interrupt current playback and play this song immediately',
              icon: Icons.play_arrow_rounded,
              iconColor: Colors.white,
              iconBgColor: accentColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () =>
                  Navigator.of(context).pop(PlayOrQueueAction.playNow),
            ),

            const SizedBox(height: 10),

            // Option 2: Play Next (Queue)
            _ActionTile(
              title: 'Play Next',
              subtitle: 'Add to queue so this will be the next song to play',
              icon: Icons.playlist_play_rounded,
              iconColor: accentColor,
              iconBgColor: accentColor.withValues(alpha: 0.18),
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () =>
                  Navigator.of(context).pop(PlayOrQueueAction.playNext),
            ),

            const SizedBox(height: 12),

            // Cancel button
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
