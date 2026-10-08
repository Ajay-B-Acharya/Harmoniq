import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/youtube_video.dart';
import '../services/audio_service.dart';
import '../services/youtube_links.dart';
import '../services/youtube_catalog.dart';
import '../theme/app_colors.dart';
import '../widgets/motion.dart';
import '../widgets/song_tile.dart';
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

  const SearchScreen({
    super.key,
    required this.audioService,
    required this.onSongTap,
    required this.onFavoriteTap,
    this.searchVideos,
    this.youtubeConfigured,
    this.onVideoTap,
    this.onVideoQueueTap,
  });

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
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
        if (_recent.length > 6) _recent.removeLast();
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
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EnterTransition(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find songs, artists, and music links',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search songs, artists, or audio links',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        onPressed: _controller.clear,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.audioService,
                builder: (context, _) {
                  _refreshLocal();
                  return _query.isEmpty ? _empty() : _results();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _chip(String text, SearchFilter filter) => ChoiceChip(
    label: Text(text),
    selected: _filter == filter,
    showCheckmark: false,
    selectedColor: AppColors.accent,
    labelStyle: TextStyle(
      color: _filter == filter ? Colors.white : AppColors.textSecondary,
      fontWeight: _filter == filter ? FontWeight.w700 : FontWeight.w500,
      fontSize: 12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    side: BorderSide(
      color: _filter == filter ? Colors.transparent : AppColors.surfaceBorder,
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

  Widget _empty() {
    final heading = 'Play here. Stay here.';
    final subtext = _configured
        ? 'Start somewhere good.'
        : 'No external app will be opened.';
    return ListView(
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
        const SizedBox(height: 20),
        if (_recent.isNotEmpty) ...[
          const Text(
            'Recent searches',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ..._recent.map(
            (query) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded, size: 18, color: AppColors.textMuted),
              title: Text(
                query,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
              ),
              trailing: const Icon(Icons.north_west_rounded, size: 16, color: AppColors.textMuted),
              onTap: () => setQuery(query),
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Browse by genre',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Acoustic',
            'Electronic',
            'Instrumental',
            'Chill',
            'Rock',
            'Jazz',
            'Ambient',
            'Lo-Fi',
          ]
              .map(
                (tag) => ActionChip(
                  label: Text(tag),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setQuery(tag),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                  backgroundColor: AppColors.surfaceHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: AppColors.accent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paste any audio or video link in search to play it directly.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }


  Widget _results() {
    final showLocal = _filter != SearchFilter.online;
    final showOnline = _filter != SearchFilter.local;
    final id = YoutubeLinks.videoIdFromInput(_query);

    return CustomScrollView(
      slivers: [
        if (showOnline) ...[
          if (id != null)
            SliverToBoxAdapter(
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Play this song'),
              ),
            )
          else if (_configured)
            SliverToBoxAdapter(
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
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_loading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          if (_videos.isNotEmpty)
            SliverList.builder(
              itemCount: _videos.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: YoutubeCard(
                  video: _videos[index],
                  onTap: () => _playResult(_videos[index]),
                ),
              ),
            ),
          if (!_loading &&
              _error == null &&
              _submitted == _query &&
              _videos.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'No tracks found. Try a different query.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
        ],
        if (showLocal) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
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
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'No local results found',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: _local.length,
            itemBuilder: (context, index) {
              final song = _local[index].copyWith(
                isFavorite: widget.audioService.isSongFavorite(_local[index]),
              );
              final active = widget.audioService.currentSong == song;
              return SongTile(
                song: song,
                isActive: active,
                isPlaying: active && widget.audioService.isPlaying,
                onTap: () => widget.onSongTap(song),
                onFavoriteTap: () => widget.onFavoriteTap(song),
              );
            },
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
