import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_service.dart';
import '../models/song.dart';
import '../theme/app_colors.dart';
import '../widgets/song_tile.dart';
import '../widgets/spatial_background.dart';
import '../utils/local_song_sort.dart';

class LocalScreen extends StatefulWidget {
  final AudioService audioService;
  final Function(Song) onSongTap;
  final Function(Song) onFavoriteTap;
  final Future<void> Function() onScanTap;

  const LocalScreen({
    super.key,
    required this.audioService,
    required this.onSongTap,
    required this.onFavoriteTap,
    required this.onScanTap,
  });

  @override
  State<LocalScreen> createState() => _LocalScreenState();
}

class _LocalScreenState extends State<LocalScreen> {
  static const _platform = MethodChannel('com.example.harmoniq/local_music');

  // Tracks whether we've already attempted the auto-scan this lifecycle so we
  // don't fire it repeatedly on rebuilds.
  bool _autoScanAttempted = false;
  LocalSongSort _sort = LocalSongSort.titleAscending;

  @override
  void initState() {
    super.initState();
    _autoScanIfPermitted();
  }

  /// If storage permission is already granted and no local songs have been
  /// loaded yet, trigger a scan immediately — no dialog, no tap required.
  Future<void> _autoScanIfPermitted() async {
    if (_autoScanAttempted) return;
    _autoScanAttempted = true;

    // Nothing to do if songs are already loaded or a scan is running.
    if (widget.audioService.localSongs.isNotEmpty ||
        widget.audioService.isScanning) {
      return;
    }

    try {
      final bool granted =
          await _platform.invokeMethod<bool>('checkPermission') ?? false;
      if (granted &&
          mounted &&
          widget.audioService.localSongs.isEmpty &&
          !widget.audioService.isScanning) {
        await widget.onScanTap();
      }
    } catch (e) {
      debugPrint('[LOCAL_SCREEN] Auto-scan check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpatialNebulaBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // ── Header — static, does NOT rebuild on audio events ─────────
                ListenableBuilder(
                  listenable: widget.audioService,
                  builder: (context, _) {
                    final isScanning = widget.audioService.isScanning;
                    final localSongs = widget.audioService.localSongs;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Local Music',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                              ),
                            ),
                            if (!isScanning)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PopupMenuButton<LocalSongSort>(
                                    tooltip: 'Sort local songs',
                                    color: AppColors.sheetSurface,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 44,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.glassSecondary,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.borderStandard,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.sort_rounded,
                                            color: AppColors.accentLight,
                                            size: 19,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _sort.shortLabel,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onSelected: (sort) =>
                                        setState(() => _sort = sort),
                                    itemBuilder: (context) => LocalSongSort
                                        .values
                                        .map(
                                          (sort) => CheckedPopupMenuItem(
                                            value: sort,
                                            checked: sort == _sort,
                                            child: Text(sort.label),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  IconButton(
                                    tooltip: 'Scan device',
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      color: AppColors.textPrimary,
                                      size: 24,
                                    ),
                                    onPressed: widget.onScanTap,
                                    splashRadius: 24,
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (localSongs.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${localSongs.length} songs on device',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                // ── Body — only this rebuilds on audio events ─────────────────
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.audioService,
                    builder: (context, _) {
                      final localSongs = widget.audioService.localSongs;
                      final isScanning = widget.audioService.isScanning;
                      final currentSong = widget.audioService.currentSong;
                      final isPlaying = widget.audioService.isPlaying;
                      return _buildBody(
                        context,
                        localSongs: sortLocalSongs(localSongs, _sort),
                        isScanning: isScanning,
                        currentSong: currentSong,
                        isPlaying: isPlaying,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<Song> localSongs,
    required bool isScanning,
    required Song? currentSong,
    required bool isPlaying,
  }) {
    if (isScanning) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                'Scanning device for audio files...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    if (localSongs.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_android_rounded,
                size: 56,
                color: AppColors.textMuted.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No local songs found',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Scan your device for music. Allow audio access when prompted.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onScanTap,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Scan Storage / Grant Access'),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: localSongs.length + 1,
      itemBuilder: (context, index) {
        if (index == localSongs.length) {
          return const SizedBox(height: 130);
        }
        final song = localSongs[index];
        final isActive = currentSong?.identity == song.identity;
        return SongTile(
          song: song,
          isActive: isActive,
          isPlaying: isActive && isPlaying,
          onTap: () => widget.onSongTap(song),
          onFavoriteTap: () => widget.onFavoriteTap(song),
        );
      },
    );
  }
}
