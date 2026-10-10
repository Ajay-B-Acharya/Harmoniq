import 'package:flutter/material.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../models/youtube_video.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/youtube_catalog.dart';
import '../theme/app_colors.dart';
import '../widgets/account_dialog.dart';
import '../widgets/album_art.dart';
import '../widgets/harmoniq_emblem.dart';
import '../widgets/motion.dart';
import '../widgets/song_card.dart';
import '../widgets/spatial_background.dart';
import '../widgets/youtube_card.dart';

/// Redesigned Spatial UI Home screen inspired by the SoundWave reference.
/// Features atmospheric ambient lighting, "Good Vibes Only" hero carousel,
/// horizontal recently played cards, and "Recommended for you" glass list.
class HomeScreen extends StatefulWidget {
  final AudioService audioService;
  final AuthService? authService;
  final Function(Song, [List<Song>? queue]) onSongTap;
  final Function(Playlist) onPlaylistPlayTap;
  final VoidCallback? onLocalTap;
  final ValueChanged<String>? onSearchTap;
  final ValueChanged<YoutubeVideo>? onVideoTap;
  final void Function(YoutubeVideo, List<YoutubeVideo>)? onVideoQueueTap;
  final VoidCallback? onProfileTap;
  final bool? youtubeConfigured;
  final Future<List<YoutubeVideo>> Function()? loadVideos;

  const HomeScreen({
    super.key,
    required this.audioService,
    this.authService,
    required this.onSongTap,
    required this.onPlaylistPlayTap,
    this.onLocalTap,
    this.onSearchTap,
    this.onVideoTap,
    this.onVideoQueueTap,
    this.onProfileTap,
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
  final int _bannerIndex = 0;

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
      final videos =
          await (widget.loadVideos?.call() ??
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
              : 'Discovery is unavailable. Try a search or paste a link.';
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

  void _playHeroBanner() {
    final all = widget.audioService.allAvailableSongs;
    if (all.isNotEmpty) {
      widget.onSongTap(all.first, all);
    } else if (_videos.isNotEmpty) {
      _playResult(_videos.first);
    } else {
      widget.onSearchTap?.call('Chill beats');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpatialBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primaryViolet,
            backgroundColor: AppColors.backgroundSecondary,
            onRefresh: () => _load(refresh: true),
            child: ListenableBuilder(
              listenable: widget.audioService,
              builder: (context, _) {
                final currentSong = widget.audioService.currentSong;
                final isPlaying = widget.audioService.isPlaying;
                final recentlyPlayed = widget.audioService.recentlyPlayed;
                final favorites = widget.audioService.favorites;
                final playlists = widget.audioService.playlists;
                final allSongs = widget.audioService.allAvailableSongs;

                // Recommended list: fallback to allAvailableSongs if favorites/history empty
                final recommendedSongs = allSongs.isNotEmpty
                    ? allSongs
                    : <Song>[];

                return CustomScrollView(
                  key: const PageStorageKey('home-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // ── Header (Screenshot 4) ─────────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            // Brand Emblem
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.glassBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.glassBorder,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const HarmoniqEmblem(size: 24),
                            ),
                            const SizedBox(width: 10),

                            // Brand Title
                            const Expanded(
                              child: Text(
                                'Harmoniq',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Search music action button
                            IconButton(
                              tooltip: 'Search music',
                              onPressed: () => widget.onSearchTap?.call(''),
                              icon: const Icon(
                                Icons.search_rounded,
                                size: 22,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            // Profile avatar thumbnail with glowing ring
                            GestureDetector(
                              onTap: () {
                                if (widget.onProfileTap != null) {
                                  widget.onProfileTap!();
                                } else if (widget.authService != null) {
                                  AccountDialog.show(
                                    context,
                                    authService: widget.authService!,
                                    onAuthChanged: () => setState(() {}),
                                  );
                                }
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.backgroundSurface,
                                  border: Border.all(
                                    color: AppColors.surfaceBorder,
                                  ),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.backgroundSecondary,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 20,
                                    color: AppColors.accentLight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Hero Featured Card ("Good Vibes Only") ────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      sliver: SliverToBoxAdapter(child: _buildHeroBanner()),
                    ),

                    // ── Continue Listening (if active track) ─────────────────
                    if (currentSong != null)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverToBoxAdapter(
                          child: _buildContinueListeningCard(
                            currentSong,
                            isPlaying,
                          ),
                        ),
                      ),

                    // ── Recently Played (Screenshot 4) ───────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _sectionHeader(
                          title: 'Recently Played',
                          onSeeAll: () => widget.onSearchTap?.call(''),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 210,
                        child: recentlyPlayed.isNotEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: recentlyPlayed.length,
                                itemBuilder: (context, index) {
                                  final song = recentlyPlayed[index];
                                  return SongCard(
                                    song: song,
                                    onTap: () =>
                                        widget.onSongTap(song, recentlyPlayed),
                                  );
                                },
                              )
                            : _buildFallbackRecentRow(),
                      ),
                    ),

                    // ── Recommended for you (Screenshot 4) ────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _sectionHeader(
                          title: 'Recommended for you',
                          onSeeAll: () => widget.onSearchTap?.call(''),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.surfaceBorder),
                              bottom: BorderSide(
                                color: AppColors.surfaceBorder,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: recommendedSongs.isNotEmpty
                              ? Column(
                                  children: List.generate(
                                    recommendedSongs.length.clamp(0, 5),
                                    (index) {
                                      final song = recommendedSongs[index];
                                      return _buildRecommendedRow(
                                        song,
                                        recommendedSongs,
                                      );
                                    },
                                  ),
                                )
                              : const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: Text(
                                      'Explore music to get tailored recommendations',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // ── Available Online Music (YoutubeCatalog) ───────────────
                    if (_configured) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Available Streams',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Refresh tracks',
                                onPressed: _loading
                                    ? null
                                    : () => _load(refresh: true),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                ),
                                color: AppColors.textMuted,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryViolet,
                              ),
                            ),
                          ),
                        ),
                      if (_error != null)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              _error!,
                              style: const TextStyle(
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
                            itemCount: _videos.length.clamp(0, 6),
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.glassBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            padding: const EdgeInsets.all(16),
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
                                  icon: const Icon(
                                    Icons.search_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Find a song'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    side: const BorderSide(
                                      color: AppColors.glassBorder,
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    // ── Quick Access & Local Music ───────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: const Text(
                          'Collections',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 72,
                        child: SingleChildScrollView(
                          key: const PageStorageKey('home-collections'),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 156,
                                child: _collectionCard(
                                  title: 'Liked Songs',
                                  subtitle: '${favorites.length} songs',
                                  icon: Icons.favorite_rounded,
                                  iconColor: AppColors.heartColor,
                                  onTap: () => widget.onSearchTap?.call(''),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 156,
                                child: _collectionCard(
                                  title: 'Playlists',
                                  subtitle: '${playlists.length} playlists',
                                  icon: Icons.queue_music_rounded,
                                  iconColor: AppColors.accentLight,
                                  onTap: () => widget.onSearchTap?.call(''),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 156,
                                child: _collectionCard(
                                  title: 'Local Device',
                                  subtitle: 'Offline collection',
                                  icon: Icons.folder_open_rounded,
                                  iconColor: AppColors.accentLight,
                                  onTap: widget.onLocalTap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF293A3E), Color(0xFF182329), Color(0xFF121A20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Good Vibes\nOnly',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Curated playlist for your best moments.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                children: [
                  Pressable(
                    onTap: _playHeroBanner,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 19,
                            color: Color(0xFF101717),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Play Now',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101717),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final active = i == _bannerIndex;
                      return Container(
                        width: active ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackRecentRow() {
    final all = widget.audioService.allAvailableSongs;
    if (all.isNotEmpty) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: all.length.clamp(0, 6),
        itemBuilder: (context, index) => SongCard(
          song: all[index],
          onTap: () => widget.onSongTap(all[index], all),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          'Start playing songs to see them here',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildRecommendedRow(Song song, List<Song> queue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Rounded artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: AlbumArt(
                gradientId: song.gradientId,
                size: 48,
                borderRadius: 12,
                showShadow: false,
                imageUrl: song.albumArtUrl,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Artist
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onSongTap(song, queue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Heart icon
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
            onPressed: () => widget.audioService.toggleFavorite(song),
          ),

          // Circular play button (Screenshot 4)
          GestureDetector(
            onTap: () => widget.onSongTap(song, queue),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF101522),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueListeningCard(Song song, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          AlbumArt(
            gradientId: song.gradientId,
            size: 56,
            borderRadius: 14,
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
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.softCyan,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
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
          IconButton(
            tooltip: isPlaying ? 'Pause' : 'Play',
            onPressed: widget.audioService.togglePlay,
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: AppColors.accentLight,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _collectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
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
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String label;
  final String query;
  final void Function(String)? onTap;

  const _MoodChip({required this.label, required this.query, this.onTap});

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    labelStyle: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
    onPressed: () => onTap?.call(query),
    side: const BorderSide(color: AppColors.glassBorder),
    backgroundColor: AppColors.glassBackground,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
