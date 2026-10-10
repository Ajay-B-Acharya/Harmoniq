import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/youtube_video.dart';
import '../services/audio_service.dart';
import '../services/youtube_catalog.dart';
import '../services/youtube_links.dart';
import '../theme/app_colors.dart';
import '../widgets/harmoniq_emblem.dart';
import '../widgets/motion.dart';
import '../widgets/song_tile.dart';
import '../widgets/spatial_background.dart';
import '../widgets/youtube_card.dart';

enum SearchFilter { all, local, online }

class SearchScreen extends StatefulWidget {
  final AudioService audioService;
  final ValueChanged<Song> onSongTap;
  final ValueChanged<Song> onFavoriteTap;
  final Future<List<YoutubeVideo>> Function(String)? searchVideos;
  final bool? youtubeConfigured;
  final ValueChanged<YoutubeVideo>? onVideoTap;
  final void Function(YoutubeVideo, List<YoutubeVideo>)? onVideoQueueTap;
  final VoidCallback? onProfileTap;

  const SearchScreen({
    super.key,
    required this.audioService,
    required this.onSongTap,
    required this.onFavoriteTap,
    this.searchVideos,
    this.youtubeConfigured,
    this.onVideoTap,
    this.onVideoQueueTap,
    this.onProfileTap,
  });

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  SearchFilter _filter = SearchFilter.all;
  List<Song> _local = [];
  List<YoutubeVideo> _videos = [];
  String _query = '';
  String? _submitted;
  String? _error;
  bool _loading = false;
  int _generation = 0;
  int _localRevision = -1;
  String? _localQuery;
  final List<String> _recent = [];

  bool get _configured =>
      widget.youtubeConfigured ??
      (widget.searchVideos != null || YoutubeCatalog.instance.isAvailable);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void setQuery(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
  }

  void _changed() {
    final query = _controller.text.trim();
    if (query == _query) return;
    setState(() {
      _query = query;
      _generation++;
      _loading = false;
      _videos = [];
      _error = null;
      _submitted = null;
      _refreshLocal();
    });
  }

  void _refreshLocal() {
    if (_localRevision == widget.audioService.localSongsRevision &&
        _localQuery == _query) {
      return;
    }
    _localRevision = widget.audioService.localSongsRevision;
    _localQuery = _query;
    final lower = _query.toLowerCase();
    _local = lower.isEmpty
        ? []
        : widget.audioService.localSongs
            .where(
              (song) =>
                  song.title.toLowerCase().contains(lower) ||
                  song.artist.toLowerCase().contains(lower) ||
                  song.album.toLowerCase().contains(lower),
            )
            .toList();
  }

  Future<void> _submit() async {
    if (_query.isEmpty || _filter == SearchFilter.local) return;
    final id = YoutubeLinks.videoIdFromInput(_query);
    if (id != null) {
      widget.onVideoTap?.call(
        YoutubeVideo(
          id: id,
          title: 'YouTube track',
          artist: 'YouTube',
          thumbnailUrl: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
        ),
      );
      return;
    }
    if (!_configured) return;
    final query = _query;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _submitted = query;
    });
    try {
      final result =
          await (widget.searchVideos?.call(query) ??
              YoutubeCatalog.instance.search(query));
      if (!mounted || generation != _generation) return;
      setState(() {
        _videos = result;
        _loading = false;
        _recent.remove(query);
        _recent.insert(0, query);
        if (_recent.length > 8) _recent.removeLast();
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = error is YoutubeSourceException
            ? error.message
            : 'Could not load search results. Please try again.';
      });
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
      backgroundColor: AppColors.background,
      body: SpatialBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header (Screenshot 2) ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
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
                      alignment: Alignment.center,
                      child: const HarmoniqEmblem(size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Search',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Container(
                        width: 38,
                        height: 38,
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.softCyan, AppColors.primaryViolet],
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.backgroundSecondary,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 19,
                            color: AppColors.softCyan,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Translucent Search Bar (Screenshot 2) ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? AppColors.primaryViolet
                          : AppColors.primaryViolet.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryViolet.withValues(alpha: 0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            hintText: 'Search artists, songs, playlists...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _query = '';
                              _videos = [];
                              _error = null;
                            });
                          },
                        )
                      else
                        const Icon(
                          Icons.mic_none_rounded,
                          color: AppColors.softCyan,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _chip('All', SearchFilter.all),
                    const SizedBox(width: 8),
                    _chip('Local', SearchFilter.local),
                    const SizedBox(width: 8),
                    _chip('Online', SearchFilter.online),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Main Content Area ───────────────────────────────────────
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.audioService,
                  builder: (context, _) {
                    _refreshLocal();
                    return _query.isEmpty
                        ? _buildDiscoveryLanding()
                        : _buildSearchResults();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, SearchFilter filter) => ChoiceChip(
    label: Text(text),
    selected: _filter == filter,
    showCheckmark: false,
    selectedColor: AppColors.primaryViolet,
    backgroundColor: AppColors.glassBackground,
    labelStyle: TextStyle(
      color: _filter == filter ? Colors.white : AppColors.textSecondary,
      fontWeight: _filter == filter ? FontWeight.w700 : FontWeight.w500,
      fontSize: 12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    side: BorderSide(
      color: _filter == filter ? AppColors.primaryViolet : AppColors.glassBorder,
      width: 1,
    ),
    onSelected: (_) => setState(() {
      _filter = filter;
      if (filter == SearchFilter.local) {
        _generation++;
        _loading = false;
      }
    }),
  );

  // ── Discovery Landing View (Screenshot 2: Recent, Categories, Trending) ───
  Widget _buildDiscoveryLanding() {
    final heading = 'Play here. Stay here.';
    final subtext = _configured
        ? 'Start somewhere good.'
        : 'No external app will be opened.';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 96),
      children: [
        Text(
          heading,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtext,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        // Recent Searches
        if (_recent.isNotEmpty) ...[
          const Text(
            'Recent searches',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: List.generate(_recent.length, (index) {
                final item = _recent[index];
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        dense: true,
                        title: Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() => _recent.removeAt(index));
                          },
                        ),
                        onTap: () {
                          setQuery(item);
                          _submit();
                        },
                      ),
                    ),
                    if (index < _recent.length - 1)
                      const Divider(
                        color: AppColors.glassBorder,
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Search by Category (Screenshot 2)
        const Text(
          'Search by Category',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _categoryCard('Top Playlists', const [Color(0xFF261D5A), Color(0xFF130E2B)], hasPlay: true),
            _categoryCard('New Releases', const [Color(0xFF194052), Color(0xFF0C2029)]),
            _categoryCard('Pop', const [Color(0xFF5D1E5A), Color(0xFF2E0F2D)], isHighlighted: true),
            _categoryCard('Bollywood', const [Color(0xFF5A311D), Color(0xFF29160D)]),
            _categoryCard('Hip-Hop', const [Color(0xFF1D345A), Color(0xFF0D1729)]),
            _categoryCard('Podcasts', const [Color(0xFF381D5A), Color(0xFF1A0D29)]),
          ],
        ),

        const SizedBox(height: 24),

        // Trending Search (Screenshot 2)
        const Text(
          'Trending Search',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              _trendingSearchTile('#1 Sunset Drive', 'Arijit Singh'),
              const Divider(color: AppColors.glassBorder, height: 1, indent: 16, endIndent: 16),
              _trendingSearchTile('#2 Chill Beats', 'Lofi Sound'),
              const Divider(color: AppColors.glassBorder, height: 1, indent: 16, endIndent: 16),
              _trendingSearchTile('#3 Vintage Hits', 'Classic 90s'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(
    String label,
    List<Color> gradient, {
    bool hasPlay = false,
    bool isHighlighted = false,
  }) {
    final width = (MediaQuery.of(context).size.width - 52) / 2;
    return Pressable(
      onTap: () {
        setQuery(label);
        _submit();
      },
      child: Container(
        width: width,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHighlighted
                ? AppColors.primaryViolet
                : AppColors.glassBorder,
            width: isHighlighted ? 1.5 : 1.0,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primaryViolet.withValues(alpha: 0.3),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hasPlay)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF101522),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _trendingSearchTile(String title, String subtitle) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: const Icon(
          Icons.local_fire_department_rounded,
          color: Color(0xFFFF7A45),
          size: 20,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 13,
          color: AppColors.textMuted,
        ),
        onTap: () {
          setQuery(title.replaceFirst(RegExp(r'#\d+\s+'), ''));
          _submit();
        },
      ),
    );
  }

  // ── Results List View ──────────────────────────────────────────────────────
  Widget _buildSearchResults() {
    final showLocal = _filter != SearchFilter.online;
    final showOnline = _filter != SearchFilter.local;
    final id = YoutubeLinks.videoIdFromInput(_query);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (showOnline) ...[
          if (id != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Play this song'),
                ),
              ),
            )
          else if (_configured)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: const Icon(Icons.search_rounded, size: 17),
                    label: Text(
                      _error != null ? 'Retry search' : 'Search online',
                    ),
                  ),
                ),
              ),
            ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryViolet,
                  ),
                ),
              ),
            ),
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          if (_videos.isNotEmpty) ...[
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'STREAMING RESULTS',
                  style: TextStyle(
                    color: AppColors.primaryViolet,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: _videos.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: YoutubeCard(
                    video: _videos[index],
                    onTap: () => _playResult(_videos[index]),
                  ),
                ),
              ),
            ),
          ],
          if (!_loading &&
              _error == null &&
              _submitted == _query &&
              _videos.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  'No tracks found. Try a different query.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
        ],
        if (showLocal) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Text(
                'On your device · ${_local.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (_local.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No local results found',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: _local.length,
              itemBuilder: (context, index) {
                final song = _local[index].copyWith(
                  isFavorite: widget.audioService.isSongFavorite(_local[index]),
                );
                final active = widget.audioService.currentSong == song;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SongTile(
                    song: song,
                    isActive: active,
                    isPlaying: active && widget.audioService.isPlaying,
                    onTap: () => widget.onSongTap(song),
                    onFavoriteTap: () => widget.onFavoriteTap(song),
                  ),
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}
