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
import '../widgets/avatar_halo.dart';
import '../widgets/glass_card.dart';
import '../widgets/harmoniq_emblem.dart';
import '../widgets/motion.dart';
import '../widgets/neumorphic.dart';
import '../widgets/song_card.dart';
import '../widgets/spatial_background.dart';
import '../widgets/youtube_card.dart';
import 'history_screen.dart';
import 'main_card_screen.dart';

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
  bool _fastBlocking = true;
  double _transactionLimit = 2000.0;

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
      body: SpatialNebulaBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primaryCyan,
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
                            // Brand Emblem / Neumorphic Menu Trigger
                            GestureDetector(
                              onTap: _openNeumorphicMenu,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      offset: const Offset(-2, -2),
                                      blurRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: AppColors.darkShadow.withValues(alpha: 0.65),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const HarmoniqEmblem(size: 24),
                              ),
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

                            // Profile avatar thumbnail with restrained gradient halo
                            AvatarHalo(
                              size: 38,
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
                              child: const Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Hero Featured Card ("Good Vibes Only") ────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      sliver: SliverToBoxAdapter(
                        child: _buildHeroBanner(
                          recentlyPlayed.isNotEmpty
                              ? recentlyPlayed.first
                              : (allSongs.isNotEmpty ? allSongs.first : null),
                        ),
                      ),
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
                              top: BorderSide(color: AppColors.divider),
                              bottom: BorderSide(color: AppColors.divider),
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
                                        showDivider:
                                            index <
                                            recommendedSongs.length.clamp(
                                                  0,
                                                  5,
                                                ) -
                                                1,
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
                                color: AppColors.primaryCyan,
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

                    // ── Neumorphic Soft 3D Showcase & Controls ──────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      sliver: SliverToBoxAdapter(
                        child: _buildNeumorphicSection(),
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

  void _openNeumorphicMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkShadow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Neumorphic Experience',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.credit_card_rounded, color: AppColors.coral),
                title: const Text('Main Card (VISA)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Toggles, limits & card controls'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MainCardScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_rounded, color: AppColors.coral),
                title: const Text('History & 3D Analytics', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('3D Rainbow Donut Chart & Activity'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_rounded, color: AppColors.coral),
                title: const Text('Local Device Music', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Browse stored audio files'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onLocalTap?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two quick feature cards: Main Card & History (horizontally scrollable for small screens)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              SizedBox(
                width: 164,
                child: NeumorphicButton(
                  borderRadius: 20,
                  depth: 4.5,
                  padding: const EdgeInsets.all(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MainCardScreen()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    offset: const Offset(-1, -1),
                                    blurRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: AppColors.darkShadow.withValues(alpha: 0.6),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'VISA',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'sans-serif',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: AppColors.coral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Main Card',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '**** 1385',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 164,
                child: NeumorphicButton(
                  borderRadius: 20,
                  depth: 4.5,
                  padding: const EdgeInsets.all(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    offset: const Offset(-1, -1),
                                    blurRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: AppColors.darkShadow.withValues(alpha: 0.6),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Text(
                                '3D CHART',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.coral,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: AppColors.coral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '30% (Food)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Neumorphic Controls Card (Fast blocking & Transaction limit)
        NeumorphicBox(
          borderRadius: 22,
          depth: 4.5,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: AppColors.coral),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Soft 3D Controls',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.9),
                          offset: const Offset(-1, -1),
                          blurRadius: 2,
                        ),
                        BoxShadow(
                          color: AppColors.darkShadow.withValues(alpha: 0.6),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Fast blocking Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textPrimary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fast blocking',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeumorphicSwitch(
                    value: _fastBlocking,
                    onChanged: (val) => setState(() => _fastBlocking = val),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Transaction Limit Slider Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Transaction Limit:',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '\$${_transactionLimit.toInt()}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              NeumorphicSlider(
                value: _transactionLimit,
                min: 500,
                max: 5000,
                onChanged: (val) => setState(() => _transactionLimit = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(Song? featuredSong) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final bannerHeight = 200 + (textScale - 1).clamp(0, 1).toDouble() * 260;

    return GlassCard(
      borderRadius: 24,
      blurSigma: 5,
      level: GlassLevel.floating,
      tint: GlassTint.cyan,
      borderColor: AppColors.borderElevated,
      child: SizedBox(
        height: bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (featuredSong != null)
              Positioned(
                top: 16,
                right: -16,
                bottom: 16,
                child: Opacity(
                  opacity: 0.92,
                  child: AlbumArt(
                    gradientId: featuredSong.gradientId,
                    size: 158,
                    borderRadius: 22,
                    imageUrl: featuredSong.albumArtUrl,
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.background.withValues(alpha: 0.72),
                    AppColors.background.withValues(alpha: 0.36),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.56, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Vibes\nOnly',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: 7),
                      SizedBox(
                        width: 190,
                        child: Text(
                          'Curated playlist for your best moments.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Pressable(
                        onTap: _playHeroBanner,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.glassSelected,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.dockActiveBorder,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowActiveCyan,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Play Now',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
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
                                  ? AppColors.lightCyan
                                  : Colors.white.withValues(alpha: 0.20),
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
          ],
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

  Widget _buildRecommendedRow(
    Song song,
    List<Song> queue, {
    required bool showDivider,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 7),
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
                color: AppColors.playControlForeground,
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
        color: AppColors.glassSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStandard),
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
              color: AppColors.primaryCyan,
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
          color: AppColors.glassSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderStandard),
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
