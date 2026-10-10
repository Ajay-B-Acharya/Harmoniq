import 'dart:math';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/youtube_video.dart';
import '../services/audio_service.dart';
import '../services/youtube_catalog.dart';
import '../theme/app_colors.dart';
import '../widgets/harmoniq_emblem.dart';
import '../widgets/motion.dart';
import '../widgets/song_tile.dart';
import '../widgets/spatial_background.dart';

/// Dedicated Spatial UI Explore / Discovery screen inspired by Screenshot 3.
/// Features "Discover New Vibes" hero banner, "Popular Genres",
/// "Trending Playlists", "Moods & Activities", and real discovered music.
class ExploreScreen extends StatefulWidget {
  final AudioService audioService;
  final Function(Song, [List<Song>? queue]) onSongTap;
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

    for (final song in service.allAvailableSongs) {
      map[song.identity] = song;
    }
    for (final song in _discoveredOnline) {
      map.putIfAbsent(song.identity, () => song);
    }

    return map.values.toList();
  }

  void _shufflePlay() {
    final catalogue = _getAllAvailable();
    if (catalogue.isEmpty) {
      widget.onSearchTap?.call('Trending Music');
      return;
    }
    final randomSong = catalogue[_random.nextInt(catalogue.length)];
    final queue = List<Song>.from(catalogue)..shuffle(_random);
    widget.onSongTap(randomSong, queue);
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = _getAllAvailable();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpatialBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primaryViolet,
            backgroundColor: AppColors.backgroundSecondary,
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
                            color: AppColors.glassBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            size: 19,
                            color: AppColors.textPrimary,
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
                                color: AppColors.backgroundSurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const HarmoniqEmblem(size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Harmoniq',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onProfileTap,
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
                            const Text(
                              'Discover New Vibes',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Search music',
                              onPressed: () => widget.onSearchTap?.call(''),
                              icon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.textSecondary,
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
                    child: const Text(
                      'Popular Genres',
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
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _genreCard('Pop', const [
                          Color(0xFF8B2B71),
                          Color(0xFF261033),
                        ]),
                        const SizedBox(width: 12),
                        _genreCard('Hip-Hop', const [
                          Color(0xFF243B6B),
                          Color(0xFF0F1836),
                        ]),
                        const SizedBox(width: 12),
                        _genreCard('Rock', const [
                          Color(0xFF6B3124),
                          Color(0xFF29100D),
                        ]),
                        const SizedBox(width: 12),
                        _genreCard('Electronic', const [
                          Color(0xFF195B6E),
                          Color(0xFF09222E),
                        ]),
                        const SizedBox(width: 12),
                        _genreCard('Bollywood', const [
                          Color(0xFF6E4219),
                          Color(0xFF2E1B09),
                        ]),
                      ],
                    ),
                  ),
                ),

                // ── Trending Playlists (Screenshot 3) ────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: const Text(
                      'Trending Playlists',
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
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _trendingPlaylistCard(
                          title: 'Global Hits',
                          icon: Icons.public_rounded,
                          gradient: const [
                            Color(0xFF1B3B59),
                            Color(0xFF0C1B2B),
                          ],
                          onTap: () {
                            if (catalogue.isNotEmpty) {
                              widget.onSongTap(catalogue.first, catalogue);
                            } else {
                              widget.onSearchTap?.call('Global Hits');
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        _trendingPlaylistCard(
                          title: 'Viral Tracks',
                          icon: Icons.star_rounded,
                          gradient: const [
                            Color(0xFF481C5E),
                            Color(0xFF1F0B2B),
                          ],
                          onTap: () {
                            if (catalogue.length > 1) {
                              widget.onSongTap(catalogue[1], catalogue);
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
                    child: const Text(
                      'Moods & Activities',
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
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _moodChip(
                          'Focus',
                          Icons.album_rounded,
                          AppColors.accentLight,
                        ),
                        const SizedBox(width: 10),
                        _moodChip(
                          'Workout',
                          Icons.fitness_center_rounded,
                          const Color(0xFFFF69B4),
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
                        const Expanded(
                          child: Text(
                            'Discovered Tracks',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
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
                              color: AppColors.primaryViolet,
                            ),
                          )
                        else
                          IconButton(
                            tooltip: 'Refresh discovery tracks',
                            onPressed: () =>
                                _loadDiscoveryTracks(refresh: true),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            color: AppColors.textMuted,
                          ),
                      ],
                    ),
                  ),
                ),

                if (catalogue.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.builder(
                      itemCount: catalogue.length.clamp(0, 12),
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
                          onTap: () => widget.onSongTap(song, catalogue),
                          onFavoriteTap: () => widget.onFavoriteTap(song),
                        );
                      },
                    ),
                  )
                else
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'Pull down to refresh and discover new tracks',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverHeroBanner() {
    return Container(
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF293A3E), Color(0xFF182329), Color(0xFF121A20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover New Vibes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Live mixes, top releases & curated sounds',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
                        SizedBox(width: 6),
                        Text(
                          'Explore Now',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101717),
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
    return Pressable(
      onTap: () => widget.onSearchTap?.call('$name music'),
      child: Container(
        width: 108,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient.first.withValues(alpha: 0.7),
              AppColors.backgroundSurface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
    return Material(
      color: AppColors.backgroundSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.accentLight,
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
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
