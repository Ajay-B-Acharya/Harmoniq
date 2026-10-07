import 'dart:math';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/youtube_video.dart';
import '../services/audio_service.dart';
import '../services/youtube_catalog.dart';
import '../theme/app_colors.dart';
import '../widgets/album_art.dart';
import '../widgets/motion.dart';
import '../widgets/song_card.dart';
import '../widgets/song_tile.dart';

class MusicScreen extends StatefulWidget {
  final AudioService audioService;
  final Function(Song, [List<Song>? queue]) onSongTap;
  final Function(Song) onFavoriteTap;
  final ValueChanged<String>? onSearchTap;
  final Future<List<YoutubeVideo>> Function()? loadVideos;

  const MusicScreen({
    super.key,
    required this.audioService,
    required this.onSongTap,
    required this.onFavoriteTap,
    this.onSearchTap,
    this.loadVideos,
  });

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
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
        final videos = await (widget.loadVideos?.call() ??
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

  void _shufflePlay(List<Song> catalogue) {
    if (catalogue.isEmpty) return;
    final randomSong = catalogue[_random.nextInt(catalogue.length)];
    final queue = List<Song>.from(catalogue)..shuffle(_random);
    widget.onSongTap(randomSong, queue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.backgroundSurface,
          onRefresh: () async {
            await _loadDiscoveryTracks(refresh: true);
            if (mounted) setState(() {});
          },
          child: ListenableBuilder(
            listenable: widget.audioService,
            builder: (context, _) {
              final catalogue = _getAllAvailable();
              final history = widget.audioService.recentlyPlayed;
              final favorites = widget.audioService.favorites;

              // 1. Featured "For You" Track
              Song? featuredTrack;
              if (history.isNotEmpty) {
                featuredTrack = history.first;
              } else if (favorites.isNotEmpty) {
                featuredTrack = favorites.first;
              } else if (catalogue.isNotEmpty) {
                featuredTrack = catalogue.first;
              }

              // 2. "Because you listened to..."
              String? becauseArtist;
              List<Song> becauseSongs = [];
              if (history.isNotEmpty) {
                becauseArtist = history.first.artist;
              } else if (favorites.isNotEmpty) {
                becauseArtist = favorites.first.artist;
              }

              if (becauseArtist != null && becauseArtist.isNotEmpty) {
                becauseSongs = catalogue
                    .where((s) =>
                        s.artist.toLowerCase() == becauseArtist!.toLowerCase() &&
                        (featuredTrack == null || s.identity != featuredTrack.identity))
                    .toList();
                if (becauseSongs.isEmpty) {
                  // If no other tracks from same artist exist, show other tracks from same source
                  becauseSongs = catalogue
                      .where((s) =>
                          featuredTrack == null ||
                          s.identity != featuredTrack.identity)
                      .take(6)
                      .toList();
                }
              }

              // 3. Recommended for you (shuffled sample from available catalogue)
              final recommended = catalogue.where((s) {
                return (featuredTrack == null || s.identity != featuredTrack.identity) &&
                    !becauseSongs.any((b) => b.identity == s.identity);
              }).toList();

              // 4. Discover something new (unplayed songs or random slice)
              final playedIds = history.map((s) => s.identity).toSet();
              final unplayed = catalogue.where((s) => !playedIds.contains(s.identity)).toList();
              final discoverNew = (unplayed.isNotEmpty ? unplayed : catalogue)
                  .where((s) => s.identity != featuredTrack?.identity)
                  .take(8)
                  .toList();

              return CustomScrollView(
                key: const PageStorageKey('music-discovery-scroll'),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Music',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.6,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Personalized discovery feed',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (catalogue.isNotEmpty)
                              FilledButton.icon(
                                onPressed: () => _shufflePlay(catalogue),
                                icon: const Icon(Icons.shuffle_rounded, size: 17),
                                label: const Text('Surprise Me'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.surfaceHigh,
                                  foregroundColor: AppColors.accent,
                                  side: const BorderSide(
                                    color: AppColors.surfaceBorder,
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── 1. For You (Featured Card) ───────────────────────────
                  if (featuredTrack != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: _buildFeaturedCard(featuredTrack, catalogue),
                      ),
                    ),

                  // ── 2. Recommended for you ───────────────────────────────
                  if (recommended.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _buildSectionHeader(
                          title: 'Recommended for you',
                          subtitle: 'Hand-picked from your active collection',
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 215,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: recommended.length,
                          itemBuilder: (context, index) {
                            final song = recommended[index];
                            return SongCard(
                              song: song,
                              onTap: () =>
                                  widget.onSongTap(song, recommended),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // ── 3. Because you listened to... ────────────────────────
                  if (becauseArtist != null && becauseSongs.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _buildSectionHeader(
                          title: 'Because you listened to $becauseArtist',
                          subtitle: 'Related tracks from available music',
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 215,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: becauseSongs.length,
                          itemBuilder: (context, index) {
                            final song = becauseSongs[index];
                            return SongCard(
                              song: song,
                              onTap: () =>
                                  widget.onSongTap(song, becauseSongs),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // ── 4. Discover something new ────────────────────────────
                  if (discoverNew.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _buildSectionHeader(
                          title: 'Discover something new',
                          subtitle: 'Fresh sounds from your catalogue',
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 215,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: discoverNew.length,
                          itemBuilder: (context, index) {
                            final song = discoverNew[index];
                            return SongCard(
                              song: song,
                              onTap: () =>
                                  widget.onSongTap(song, discoverNew),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // ── 5. Continuous Discovery Feed ────────────────────────
                  if (catalogue.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _buildSectionHeader(
                          title: 'Continuous discovery feed',
                          subtitle: 'Tap any track to begin playing',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: catalogue.length,
                        itemBuilder: (context, index) {
                          final song = catalogue[index];
                          final isActive =
                              widget.audioService.currentSong?.identity ==
                                  song.identity;
                          return SongTile(
                            song: song,
                            isActive: isActive,
                            isPlaying: isActive && widget.audioService.isPlaying,
                            onTap: () =>
                                widget.onSongTap(song, catalogue),
                            onFavoriteTap: () => widget.onFavoriteTap(song),
                          );
                        },
                      ),
                    ),
                  ],

                  if (catalogue.isEmpty && !_isLoading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.explore_off_rounded,
                              size: 48,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No discovery tracks available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Scan your device or search to build your discovery catalogue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
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
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Song song, List<Song> queue) {
    final isCurrent =
        widget.audioService.currentSong?.identity == song.identity;
    final isPlaying = isCurrent && widget.audioService.isPlaying;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          AlbumArt(
            gradientId: song.gradientId,
            size: 92,
            borderRadius: 10,
            imageUrl: song.albumArtUrl,
            showShadow: false,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FOR YOU',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        if (isCurrent) {
                          widget.audioService.togglePlay();
                        } else {
                          widget.onSongTap(song, queue);
                        }
                      },
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(isPlaying ? 'Pause' : 'Play Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: song.isFavorite
                          ? 'Remove favorite'
                          : 'Add favorite',
                      icon: Icon(
                        song.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: song.isFavorite
                            ? AppColors.heartColor
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      onPressed: () => widget.onFavoriteTap(song),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
