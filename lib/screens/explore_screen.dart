import 'dart:math';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/youtube_video.dart';
import '../services/audio_service.dart';
import '../services/youtube_catalog.dart';
import '../theme/app_colors.dart';
import '../widgets/avatar_halo.dart';
import '../widgets/harmoniq_emblem.dart';
import '../widgets/motion.dart';
import '../widgets/song_tile.dart';
import '../widgets/spatial_background.dart';
import '../widgets/shimmer_skeleton.dart';

/// Dedicated Spatial UI Explore / Discovery screen inspired by Screenshot 3.
/// Features "Discover New Vibes" hero banner, "Popular Genres",
/// "Trending Playlists", "Moods & Activities", and real discovered music.
class ExploreScreen extends StatefulWidget {
  final AudioService audioService;
  final Function onSongTap;
  final Function(Song) onFavoriteTap;
  final ValueChanged<String>? onSearchTap;
  final VoidCallback? onProfileTap;
  final Future<List<YoutubeVideo>> Function()? loadVideos;

  const ExploreScreen({
    super.key,
    required this.audioService,
    required this.onSongTap,
    required this.onFavoriteTap,
    this.onSearchTap,
    this.onProfileTap,
    this.loadVideos,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  void _onSongTap(Song song, [List<Song>? queue, bool? continuous]) {
    try {
      (widget.onSongTap as dynamic)(song, queue, continuous);
    } catch (_) {
      try {
        (widget.onSongTap as dynamic)(song, queue);
      } catch (_) {
        (widget.onSongTap as dynamic)(song);
      }
    }
  }
  final Random _random = Random();
  List<Song> _discoveredOnline = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDiscoveryTracks();
  }

  Future<void> _loadDiscoveryTracks({bool refresh = false}) async {
    if (!mounted || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (YoutubeCatalog.instance.isAvailable || widget.loadVideos != null) {
        final videos =
            await (widget.loadVideos?.call() ??
                YoutubeCatalog.instance.discover(forceRefresh: refresh));
        if (mounted) {
          final onlineSongs = videos.map(Song.fromYoutube).toList();
          setState(() {
            _discoveredOnline = onlineSongs;
            _isLoading = false;
          });
          widget.audioService.registerSongs(onlineSongs);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Song> _getAllAvailable() {
    final service = widget.audioService;
    final map = <String, Song>{};

    // Discover screen strictly plays online / internet tracks — never local storage files
    for (final song in _discoveredOnline) {
      if (song.isOnline) {
        map[song.identity] = song;
      }
    }
    for (final song in service.allAvailableSongs) {
      if (song.isOnline) {
        map.putIfAbsent(song.identity, () => song);
      }
    }

    return map.values.toList();
  }

  Future<void> _shufflePlay() async {
    var catalogue = _getAllAvailable();
    if (catalogue.isEmpty) {
      if (!_isLoading) {
        await _loadDiscoveryTracks();
      }
      catalogue = _getAllAvailable();
    }
    if (catalogue.isEmpty) {
      widget.onSearchTap?.call('Trending Music');
      return;
    }
    // Filter out previously played songs so the continuous explore session is completely fresh
    final unplayed = catalogue
        .where((s) => !widget.audioService.hasSongBeenPlayed(s))
        .toList();
    final pool = unplayed.isNotEmpty ? unplayed : catalogue;
    final randomSong = pool[_random.nextInt(pool.length)];
    final queue = List<Song>.from(pool)..shuffle(_random);
    _onSongTap(randomSong, queue, true);
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = _getAllAvailable();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SpatialNebulaBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primaryCyan,
            backgroundColor: AppColors.backgroundSecondaryOf(context),
            onRefresh: () async {
              await _loadDiscoveryTracks(refresh: true);
              if (mounted) setState(() {});
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ── Top Header ──────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.cardSurfaceOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorderOf(context)),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            size: 19,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.cardSurfaceOf(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const HarmoniqEmblem(size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Harmoniq',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () {},
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        AvatarHalo(
                          size: 38,
                          onTap: widget.onProfileTap,
                          child: Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Discover New Vibes Hero Banner (Screenshot 3) ────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discover New Vibes',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryOf(context),
                                letterSpacing: -0.3,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Search music',
                              onPressed: () => widget.onSearchTap?.call(''),
                              icon: Icon(
                                Icons.search_rounded,
                                color: AppColors.textSecondaryOf(context),
                                size: 21,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildDiscoverHeroBanner(),
                      ],
                    ),
                  ),
                ),

                // ── Popular Genres (Screenshot 3) ────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Popular Genres',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _genreCard('Pop', isDark ? AppColors.categoryOceanBlueDark : AppColors.gradientOceanBlue),
                        const SizedBox(width: 12),
                        _genreCard('Hip-Hop', isDark ? AppColors.categoryElectricBlueDark : AppColors.gradientElectricBlue),
                        const SizedBox(width: 12),
                        _genreCard('Rock', isDark ? AppColors.categoryMidnightSteelDark : AppColors.gradientMidnightSteel),
                        const SizedBox(width: 12),
                        _genreCard('Electronic', isDark ? AppColors.categoryCyanDepthDark : AppColors.gradientCyanDepth),
                        const SizedBox(width: 12),
                        _genreCard('Bollywood', isDark ? AppColors.categoryBlueAuraDark : AppColors.gradientBlueAura),
                      ],
                    ),
                  ),
                ),

                // ── Trending Playlists (Screenshot 3) ────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Trending Playlists',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 72,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _trendingPlaylistCard(
                          title: 'Global Hits',
                          icon: Icons.public_rounded,
                          gradient: isDark
                              ? AppColors.categoryOceanBlueDark
                              : AppColors.gradientOceanBlue,
                          onTap: () {
                            if (catalogue.isNotEmpty) {
                              final unplayed = catalogue
                                  .where((s) => !widget.audioService.hasSongBeenPlayed(s))
                                  .toList();
                              final pool = unplayed.isNotEmpty ? unplayed : catalogue;
                              _onSongTap(pool.first, pool, true);
                            } else {
                              widget.onSearchTap?.call('Global Hits');
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        _trendingPlaylistCard(
                          title: 'Viral Tracks',
                          icon: Icons.star_rounded,
                          gradient: isDark
                              ? AppColors.categoryCyanDepthDark
                              : AppColors.gradientCyanDepth,
                          onTap: () {
                            if (catalogue.length > 1) {
                              final unplayed = catalogue
                                  .where((s) => !widget.audioService.hasSongBeenPlayed(s))
                                  .toList();
                              final pool = unplayed.isNotEmpty ? unplayed : catalogue;
                              final song = pool.length > 1 ? pool[1] : pool.first;
                              _onSongTap(song, pool, true);
                            } else {
                              widget.onSearchTap?.call('Viral Tracks');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Moods & Activities (Screenshot 3) ────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Moods & Activities',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _moodChip(
                          'Focus',
                          Icons.album_rounded,
                          AppColors.coral,
                        ),
                        const SizedBox(width: 10),
                        _moodChip(
                          'Workout',
                          Icons.fitness_center_rounded,
                          AppColors.primaryCyan,
                        ),
                        const SizedBox(width: 10),
                        _moodChip(
                          'Relax',
                          Icons.nightlight_round,
                          AppColors.electricBlue,
                        ),
                        const SizedBox(width: 10),
                        _moodChip(
                          'Road Trip',
                          Icons.directions_car_rounded,
                          AppColors.softCyan,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Real Discovered Music Collection ─────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Discovered Tracks',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.coral,
                            ),
                          )
                        else
                          IconButton(
                            tooltip: 'Refresh discovery tracks',
                            onPressed: () =>
                                _loadDiscoveryTracks(refresh: true),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            color: AppColors.textMutedOf(context),
                          ),
                      ],
                    ),
                  ),
                ),

                if (catalogue.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.builder(
                      itemCount: catalogue.length,
                      itemBuilder: (context, index) {
                        final song = catalogue[index];
                        final isPlaying =
                            widget.audioService.isPlaying &&
                            widget.audioService.currentSong?.identity ==
                                song.identity;
                        return SongTile(
                          song: song,
                          isPlaying: isPlaying,
                          isActive: isPlaying,
                          onTap: () {
                            final unplayed = catalogue
                                .where((s) =>
                                    s.identity == song.identity ||
                                    !widget.audioService.hasSongBeenPlayed(s))
                                .toList();
                            _onSongTap(
                              song,
                              unplayed.isNotEmpty ? unplayed : catalogue,
                              true,
                            );
                          },
                          onFavoriteTap: () => widget.onFavoriteTap(song),
                        );
                      },
                    ),
                  )
                else if (_isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: ShimmerSongList(count: 6),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'Pull down to refresh and discover new tracks',
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: AppColors.bottomClearanceOf(
                      context,
                      hasMiniPlayer: widget.audioService.currentSong != null,
                    ) + 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverHeroBanner() {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: AppColors.heroGradientOf(context),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.cardBorderOf(context)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowFloating,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover New Vibes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live mixes, top releases & curated sounds',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
                Pressable(
                  onTap: _shufflePlay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coral.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Explore Now',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genreCard(String name, List<Color> gradient) {
    final cardBg = AppColors.cardSurfaceOf(context);
    // Accurately blend the card gradient overlay with the surface background
    final effectiveBg = Color.alphaBlend(
      gradient.first.withValues(alpha: 0.65),
      cardBg,
    );
    // WCAG luminance threshold: use dark text on light backgrounds and light text on dark backgrounds
    final isDarkSurface = effectiveBg.computeLuminance() < 0.4;
    final labelColor = isDarkSurface
        ? AppDarkColors.textPrimary
        : AppColors.textPrimaryOf(context);

    return Pressable(
      onTap: () => widget.onSearchTap?.call('$name music'),
      child: Container(
        width: 108,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient.first.withValues(alpha: 0.65),
              cardBg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorderOf(context)),
        ),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
      ),
    );
  }

  Widget _trendingPlaylistCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final cardBg = AppColors.cardSurfaceOf(context);
    final isLightIconBg = gradient.first.computeLuminance() > 0.4;
    final iconColor = isLightIconBg
        ? AppColors.textPrimaryOf(context)
        : Colors.white;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorderOf(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                  border: isLightIconBg
                      ? Border.all(color: AppColors.cardBorderOf(context))
                      : null,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ),
              const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.coral,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moodChip(String label, IconData icon, Color color) {
    return Pressable(
      onTap: () => widget.onSearchTap?.call('$label playlist'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorderOf(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
