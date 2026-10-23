import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/neumorphic.dart';
import '../widgets/spatial_background.dart';

/// Individual Song History & Analytics Screen
///
/// Displays the authenticated user's individual playback history synced with Supabase,
/// with real-time audio playback control, source filtering (YouTube / Local),
/// album artwork, duration, and one-tap history clearing.
class HistoryScreen extends StatefulWidget {
  final AudioService? audioService;
  final AuthService? authService;
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;

  const HistoryScreen({
    super.key,
    this.audioService,
    this.authService,
    this.onBackTap,
    this.onMenuTap,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilter = 0; // 0: All, 1: YouTube, 2: Local
  final List<String> _filters = const ['All', 'YouTube', 'Local'];

  AudioService? _fallbackAudioService;

  AudioService get _effectiveAudioService {
    if (widget.audioService != null) return widget.audioService!;
    _fallbackAudioService ??= AudioService();
    return _fallbackAudioService!;
  }

  @override
  void dispose() {
    _fallbackAudioService?.dispose();
    super.dispose();
  }

  List<Song> _filterSongs(List<Song> songs) {
    if (_selectedFilter == 1) {
      return songs.where((s) => s.isYoutube).toList();
    } else if (_selectedFilter == 2) {
      return songs.where((s) => !s.isYoutube).toList();
    }
    return songs;
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return '0:00';
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatTotalListeningTime(List<Song> songs) {
    final totalSecs = songs.fold<int>(0, (sum, s) => sum + s.duration.inSeconds);
    if (totalSecs < 60) return '$totalSecs secs';
    final mins = totalSecs ~/ 60;
    if (mins < 60) return '$mins mins';
    final hours = (mins / 60.0).toStringAsFixed(1);
    return '$hours hrs';
  }

  Future<void> _handleClearHistory() async {
    final isDark = ThemeController.instance.isDark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppDarkColors.cardSurface
            : AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppDarkColors.cardBorder : AppColors.cardBorder,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'Clear History',
              style: TextStyle(
                color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to clear your listening history? This will delete your recorded playback history from Supabase and local cache.',
          style: TextStyle(
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _effectiveAudioService.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song history cleared successfully.'),
            backgroundColor: AppColors.coral,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDark;
    final textPrimary = isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
    final user = widget.authService?.currentUser;
    final isAuthed = widget.authService?.isAuthenticated ?? false;
    final audio = _effectiveAudioService;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SpatialNebulaBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: audio,
            builder: (context, _) {
              final allHistory = audio.recentlyPlayed;
              final filtered = _filterSongs(allHistory);
              final currentSong = audio.currentSong;
              final isPlaying = audio.isPlaying;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        NeumorphicIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onTap: () {
                            if (widget.onBackTap != null) {
                              widget.onBackTap!();
                            } else if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        if (allHistory.isNotEmpty)
                          NeumorphicIconButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Clear History',
                            onTap: _handleClearHistory,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Song History',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAuthed ? AppColors.accent : AppColors.coral,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isAuthed
                                    ? 'Supabase Synced • ${user?.email ?? "Individual Account"}'
                                    : 'Guest Local History • Sign in to sync across devices',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats Overview Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: NeumorphicBox(
                      borderRadius: 18,
                      depth: 3.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statTile(
                            count: '${allHistory.length}',
                            label: 'Tracks Played',
                            icon: Icons.music_note_rounded,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: isDark ? AppDarkColors.divider : AppColors.cardBorder,
                          ),
                          _statTile(
                            count: _formatTotalListeningTime(allHistory),
                            label: 'Time Listened',
                            icon: Icons.access_time_rounded,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter Segmented Control
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: NeumorphicSegmentedControl(
                      segments: _filters,
                      selectedIndex: _selectedFilter,
                      onSelected: (idx) => setState(() => _selectedFilter = idx),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Song History List / Empty State
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(textPrimary, textSecondary, isDark)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              AppColors.bottomClearanceOf(context) + 16,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, index) {
                              final song = filtered[index];
                              final isCurrent = currentSong?.id == song.id;
                              final artUrl = song.albumArtUrl;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: NeumorphicBox(
                                  borderRadius: 16,
                                  depth: isCurrent ? 2.0 : 3.0,
                                  border: isCurrent
                                      ? Border.all(color: AppColors.coral, width: 1.5)
                                      : null,
                                  padding: const EdgeInsets.all(10),
                                  onTap: () {
                                    audio.playSong(
                                      song,
                                      contextQueue: filtered,
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      // Artwork
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: artUrl != null && artUrl.isNotEmpty
                                              ? Image.network(
                                                  artUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => _fallbackArtwork(isDark),
                                                )
                                              : _fallbackArtwork(isDark),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Song Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              song.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isCurrent ? AppColors.coral : textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                // Source Chip
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: song.isYoutube
                                                        ? const Color(0xFFFF0000).withValues(alpha: 0.15)
                                                        : AppColors.coral.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Text(
                                                    song.isYoutube ? 'YouTube' : 'Local',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: song.isYoutube
                                                          ? const Color(0xFFFF4D4D)
                                                          : AppColors.coral,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // Duration & Play status
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatDuration(song.duration),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Icon(
                                            isCurrent && isPlaying
                                                ? Icons.graphic_eq_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 20,
                                            color: isCurrent ? AppColors.coral : textSecondary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statTile({
    required String count,
    required String label,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.coral),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fallbackArtwork(bool isDark) {
    return Container(
      color: isDark ? AppDarkColors.cardBorder : AppColors.cardBorder,
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: AppColors.coral, size: 24),
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicBox(
              width: 72,
              height: 72,
              shape: BoxShape.circle,
              depth: 3.5,
              child: const Icon(
                Icons.music_off_rounded,
                size: 32,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Song History Yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 0
                  ? 'Songs you play from YouTube or your local library will appear here and sync to your Supabase profile.'
                  : 'No songs found matching the selected filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
