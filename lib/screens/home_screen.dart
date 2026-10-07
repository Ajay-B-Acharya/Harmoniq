import 'package:flutter/material.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../models/youtube_video.dart';
import '../services/audio_service.dart';
import '../services/youtube_catalog.dart';
import '../theme/app_colors.dart';
import '../widgets/album_art.dart';
import '../widgets/motion.dart';
import '../widgets/song_card.dart';
import '../widgets/youtube_card.dart';

class HomeScreen extends StatefulWidget {
  final AudioService audioService;
  final Function(Song, [List<Song>? queue]) onSongTap;
  final Function(Playlist) onPlaylistPlayTap;
  final VoidCallback? onLocalTap;
  final ValueChanged<String>? onSearchTap;
  final ValueChanged<YoutubeVideo>? onVideoTap;
  final void Function(YoutubeVideo, List<YoutubeVideo>)? onVideoQueueTap;
  final bool? youtubeConfigured;
  final Future<List<YoutubeVideo>> Function()? loadVideos;

  const HomeScreen({
    super.key,
    required this.audioService,
    required this.onSongTap,
    required this.onPlaylistPlayTap,
    this.onLocalTap,
    this.onSearchTap,
    this.onVideoTap,
    this.onVideoQueueTap,
    this.youtubeConfigured,
    this.loadVideos,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<YoutubeVideo> _videos = [];
  bool _loading = false;
  String? _error;

  bool get _configured =>
      widget.youtubeConfigured ?? YoutubeCatalog.instance.isAvailable;

  @override
  void initState() {
    super.initState();
    if (_configured) _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (!_configured || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final videos = await (widget.loadVideos?.call() ??
          YoutubeCatalog.instance.discover(forceRefresh: refresh));
      if (mounted) {
        setState(() {
          _videos = videos;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is YoutubeSourceException
              ? error.message
              : 'Discovery is unavailable. Try a search or paste a video link.';
          _loading = false;
        });
      }
    }
  }

  void _playResult(YoutubeVideo video) {
    if (widget.onVideoQueueTap != null) {
      widget.onVideoQueueTap!(video, _videos);
    } else {
      widget.onVideoTap?.call(video);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.backgroundSurface,
          onRefresh: () => _load(refresh: true),
          child: ListenableBuilder(
            listenable: widget.audioService,
            builder: (context, _) {
              final currentSong = widget.audioService.currentSong;
              final isPlaying = widget.audioService.isPlaying;
              final recentlyPlayed = widget.audioService.recentlyPlayed;
              final favorites = widget.audioService.favorites;
              final playlists = widget.audioService.playlists;
              final localSongs = widget.audioService.localSongs;
              final allSongs = widget.audioService.allAvailableSongs;

              return CustomScrollView(
                key: const PageStorageKey('home-scroll'),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── Header ───────────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: EnterTransition(
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/brand_mark.png',
                                width: 34,
                                height: 34,
                                cacheWidth: 102,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Harmoniq',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton.outlined(
                              tooltip: 'Search music',
                              style: IconButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.surfaceBorder,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => widget.onSearchTap?.call(''),
                              icon: const Icon(Icons.search_rounded, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Continue Listening (if a song exists) ────────────────
                  if (currentSong != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: _buildContinueListeningCard(
                          currentSong,
                          isPlaying,
                        ),
                      ),
                    ),

                  // ── Recently Played ──────────────────────────────────────
                  if (recentlyPlayed.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _sectionHeading(
                          'Recently played',
                          'Pick up where you left off',
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 205,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: recentlyPlayed.length,
                          itemBuilder: (context, index) {
                            final song = recentlyPlayed[index];
                            return SongCard(
                              song: song,
                              onTap: () => widget.onSongTap(
                                song,
                                recentlyPlayed,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // ── Quick Access: Playlists & Library ────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _sectionHeading(
                        'Quick access',
                        'Your playlists and collections',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: _buildQuickAccessGrid(
                        favorites: favorites,
                        playlists: playlists,
                        localSongs: localSongs,
                      ),
                    ),
                  ),

                  // ── Recommended Music ────────────────────────────────────
                  if (allSongs.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _sectionHeading(
                          'Recommended music',
                          'Curated from your active collection',
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 205,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: allSongs.length.clamp(0, 10),
                          itemBuilder: (context, index) {
                            final song = allSongs[index];
                            return SongCard(
                              song: song,
                              onTap: () => widget.onSongTap(song, allSongs),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // ── Available Songs / Spotlight ──────────────────────────
                  if (_configured) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: _sectionHeading(
                                'Available music',
                                'Explore and discover available tracks',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refresh tracks',
                              onPressed: _loading
                                  ? null
                                  : () => _load(refresh: true),
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_loading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    if (_error != null)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _load(refresh: true),
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_loading && _error == null && _videos.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'No online tracks loaded right now.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    if (_videos.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.builder(
                          itemCount: _videos.length.clamp(0, 8),
                          itemBuilder: (_, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: YoutubeCard(
                              video: _videos[index],
                              onTap: () => _playResult(_videos[index]),
                            ),
                          ),
                        ),
                      ),
                  ],

                  // ── In-app Discovery (when online not configured) ─────────
                  if (!_configured) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _sectionHeading(
                          'Find your next song',
                          'Search the in-app catalogue',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YouTube · in-app',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MoodChip(
                                  label: 'After hours',
                                  query: 'Late night R&B',
                                  onTap: widget.onSearchTap,
                                ),
                                _MoodChip(
                                  label: 'Focus',
                                  query: 'Focus music',
                                  onTap: widget.onSearchTap,
                                ),
                                _MoodChip(
                                  label: 'Chill',
                                  query: 'Chill beats',
                                  onTap: widget.onSearchTap,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => widget.onSearchTap?.call(''),
                              icon: const Icon(Icons.search_rounded, size: 16),
                              label: const Text('Find a song'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.surfaceBorder,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],

                  // ── Offline Collection Banner ────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    sliver: SliverToBoxAdapter(
                      child: Pressable(
                        onTap: widget.onLocalTap,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              AlbumArt(
                                gradientId: 1,
                                size: 48,
                                borderRadius: 8,
                                showShadow: false,
                                overlayIcon: Icons.folder_open_rounded,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Offline collection',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      localSongs.isEmpty
                                          ? 'On-device music files'
                                          : '${localSongs.length} tracks on device',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueListeningCard(Song song, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          AlbumArt(
            gradientId: song.gradientId,
            size: 64,
            borderRadius: 8,
            imageUrl: song.albumArtUrl,
            showShadow: false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CONTINUE LISTENING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: isPlaying ? 'Pause' : 'Play',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 24,
            ),
            onPressed: widget.audioService.togglePlay,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid({
    required List<Song> favorites,
    required List<Playlist> playlists,
    required List<Song> localSongs,
  }) {
    final items = <Widget>[
      // Favorites tile
      _quickAccessTile(
        title: 'Liked Songs',
        subtitle: '${favorites.length} songs',
        icon: Icons.favorite_rounded,
        iconColor: AppColors.heartColor,
        onTap: () {
          final favPlaylist = playlists.firstWhere(
            (p) => p.id == 0,
            orElse: () => Playlist(id: 0, name: 'Favorites', songs: favorites, gradientId: 0),
          );
          widget.onPlaylistPlayTap(favPlaylist);
        },
      ),

      // Playlists
      ...playlists.where((p) => p.id != 0).take(2).map(
            (pl) => _quickAccessTile(
              title: pl.name,
              subtitle: '${pl.songs.length} songs',
              icon: Icons.playlist_play_rounded,
              iconColor: AppColors.accent,
              onTap: () => widget.onPlaylistPlayTap(pl),
            ),
          ),

      // Local files
      _quickAccessTile(
        title: 'Local Music',
        subtitle: '${localSongs.length} files',
        icon: Icons.audio_file_rounded,
        iconColor: AppColors.textSecondary,
        onTap: widget.onLocalTap ?? () {},
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (w) => SizedBox(
              width: (MediaQuery.of(context).size.width - 50) / 2 > 140
                  ? (MediaQuery.of(context).size.width - 50) / 2
                  : 150,
              child: w,
            ),
          )
          .toList(),
    );
  }

  Widget _quickAccessTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String label;
  final String query;
  final void Function(String)? onTap;

  const _MoodChip({
    required this.label,
    required this.query,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    labelStyle: const TextStyle(
      fontSize: 12.5,
      color: AppColors.textSecondary,
    ),
    onPressed: () => onTap?.call(query),
    side: const BorderSide(color: AppColors.surfaceBorder),
    backgroundColor: AppColors.surfaceHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
