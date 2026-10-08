import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../theme/app_colors.dart';
import '../widgets/song_tile.dart';
import '../widgets/album_art.dart';

class LibraryScreen extends StatefulWidget {
  final AudioService audioService;
  final Function(Song) onSongTap;
  final Function(Song) onFavoriteTap;
  final Function(String) onCreatePlaylist;
  final int initialCategoryIndex;

  const LibraryScreen({
    super.key,
    required this.audioService,
    required this.onSongTap,
    required this.onFavoriteTap,
    required this.onCreatePlaylist,
    this.initialCategoryIndex = 0,
  });

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  late int _selectedCategoryIndex;
  int _favoriteFilterIndex = 0; // 0 = All, 1 = Local, 2 = Legacy, 3 = YouTube

  final List<String> _categories = [
    'Songs',
    'Playlists',
    'Albums',
    'Favorites',
    'Recently Played',
    'Local',
  ];

  AudioService? _cachedService;
  int _cachedCatalogRevision = -1;
  int _cachedLocalRevision = -1;
  List<Song> _librarySongs = [];
  Map<String, List<Song>> _albumMap = {};
  List<String> _albumKeys = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = widget.initialCategoryIndex;
  }

  void _refreshLibraryCache() {
    final service = widget.audioService;
    if (identical(service, _cachedService) &&
        service.catalogRevision == _cachedCatalogRevision &&
        service.localSongsRevision == _cachedLocalRevision) {
      return;
    }
    _cachedService = service;
    _cachedCatalogRevision = service.catalogRevision;
    _cachedLocalRevision = service.localSongsRevision;

    final localIdentities =
        service.localSongs.map((song) => song.identity).toSet();
    _librarySongs = [
      ...service.localSongs,
      ...service.songs.where(
        (song) => !localIdentities.contains(song.identity),
      ),
    ];
    _albumMap = {};
    for (final song in _librarySongs) {
      _albumMap.putIfAbsent(song.album, () => []).add(song);
    }
    _albumKeys = _albumMap.keys.toList();
  }

  void selectCategory(int index) {
    if (index >= 0 && index < _categories.length) {
      setState(() => _selectedCategoryIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Title + add button ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Library',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                  ),
                  if (_selectedCategoryIndex == 1)
                    IconButton(
                      tooltip: 'New playlist',
                      icon: const Icon(
                        Icons.add_rounded,
                        color: AppColors.textPrimary,
                        size: 26,
                      ),
                      onPressed: _showCreatePlaylistDialog,
                      splashRadius: 24,
                    )
                  else if (_selectedCategoryIndex == 5)
                    IconButton(
                      tooltip: 'Scan device',
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                      onPressed: widget.audioService.scanLocalSongs,
                      splashRadius: 24,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Category chips ────────────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategoryIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.surfaceBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.audioService,
                  builder: (context, child) => _buildCategoryContent(
                    playlists: widget.audioService.playlists,
                    currentSong: widget.audioService.currentSong,
                    isPlaying: widget.audioService.isPlaying,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContent({
    required List<Playlist> playlists,
    required Song? currentSong,
    required bool isPlaying,
  }) {
    _refreshLibraryCache();
    switch (_selectedCategoryIndex) {
      case 0:
        return _buildSongsList(_librarySongs, currentSong, isPlaying);
      case 1:
        return _buildPlaylistsView(playlists);
      case 2:
        return _buildAlbumsView();
      case 3:
        return _buildFavoritesList(
          widget.audioService.favorites,
          currentSong,
          isPlaying,
        );
      case 4:
        return _buildRecentlyPlayedView(
          widget.audioService.recentlyPlayed,
          currentSong,
          isPlaying,
        );
      case 5:
        return _buildLocalSongsView(
          widget.audioService.localSongs,
          currentSong,
          isPlaying,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _onSongTap(Song song) {
    if (song.source != SongSource.legacy) {
      widget.onSongTap(song);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Previous source unavailable. Search for "${song.title}" '
          'by ${song.artist} in YouTube Music.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSongsList(
    List<Song> allSongs,
    Song? currentSong,
    bool isPlaying,
  ) {
    if (allSongs.isEmpty) {
      return _buildEmptyState(
        Icons.music_note_rounded,
        'Your library is empty',
        subtitle: 'Scan your device to add music',
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: allSongs.length + 1,
      itemBuilder: (context, index) {
        if (index == allSongs.length) return const SizedBox(height: 120);
        final song = allSongs[index];
        final isActive = currentSong?.identity == song.identity;
        return SongTile(
          song: song,
          isActive: isActive,
          isPlaying: isActive && isPlaying,
          onTap: () => _onSongTap(song),
          onFavoriteTap: () => widget.onFavoriteTap(song),
        );
      },
    );
  }

  Widget _buildPlaylistsView(List<Playlist> playlists) {
    if (playlists.isEmpty) {
      return _buildEmptyState(
        Icons.playlist_add_rounded,
        'No playlists created yet',
        subtitle: 'Tap the plus icon above to create one',
      );
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: playlists.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return GestureDetector(
          onTap: () {
            if (playlist.songs.isNotEmpty) {
              _onSongTap(playlist.songs[0]);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This playlist is empty.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => AlbumArt(
                      gradientId: playlist.gradientId,
                      size: constraints.biggest.shortestSide,
                      borderRadius: 8,
                      showShadow: false,
                      overlayIcon: Icons.playlist_play_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${playlist.songs.length} songs',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsView() {
    final albums = _albumMap;
    if (albums.isEmpty) {
      return _buildEmptyState(Icons.album_rounded, 'No albums found');
    }
    final albumKeys = _albumKeys;
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: albumKeys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final albumName = albumKeys[index];
        final albumSongs = albums[albumName]!;
        return GestureDetector(
          onTap: () => _onSongTap(albumSongs[0]),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => AlbumArt(
                      gradientId: albumSongs[0].gradientId,
                      size: constraints.biggest.shortestSide,
                      borderRadius: 8,
                      showShadow: false,
                      overlayIcon: Icons.album_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  albumName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  albumSongs[0].artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(
    List<Song> allFavorites,
    Song? currentSong,
    bool isPlaying,
  ) {
    if (allFavorites.isEmpty) {
      return _buildEmptyState(
        Icons.favorite_outline_rounded,
        'No favorites yet',
        subtitle: 'Tap the heart on a song to add it here',
      );
    }

    final localFavs =
        allFavorites.where((s) => s.source == SongSource.local).toList();
    final youtubeFavs =
        allFavorites.where((s) => s.source == SongSource.youtube).toList();
    final legacyFavs =
        allFavorites.where((s) => s.source == SongSource.legacy).toList();
    if (legacyFavs.isEmpty && _favoriteFilterIndex == 2) {
      _favoriteFilterIndex = 0;
    }

    final filtered = _favoriteFilterIndex == 1
        ? localFavs
        : _favoriteFilterIndex == 2
            ? legacyFavs
            : _favoriteFilterIndex == 3
                ? youtubeFavs
                : allFavorites;

    return Column(
      children: [
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFavFilterChip('ALL (${allFavorites.length})', 0),
              const SizedBox(width: 8),
              _buildFavFilterChip('LOCAL (${localFavs.length})', 1),
              const SizedBox(width: 8),
              _buildFavFilterChip('YOUTUBE (${youtubeFavs.length})', 3),
              if (legacyFavs.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildFavFilterChip(
                  'Previous source (${legacyFavs.length})',
                  2,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (legacyFavs.isNotEmpty &&
            (_favoriteFilterIndex == 0 || _favoriteFilterIndex == 2)) ...[
          const Text(
            'Previous-source favorites are saved but unavailable. '
            'Search their title and artist in YouTube Music.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(
                  Icons.favorite_border_rounded,
                  _favoriteFilterIndex == 1
                      ? 'No local favorite songs'
                      : _favoriteFilterIndex == 3
                          ? 'No YouTube favorite songs'
                          : 'No previous-source favorite songs',
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return const SizedBox(height: 120);
                    }
                    final song = filtered[index];
                    final isActive = currentSong?.identity == song.identity;
                    return SongTile(
                      song: song,
                      isActive: isActive,
                      isPlaying: isActive && isPlaying,
                      onTap: () => _onSongTap(song),
                      onFavoriteTap: () => widget.onFavoriteTap(song),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFavFilterChip(String label, int index) {
    final isSelected = _favoriteFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _favoriteFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.20)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.surfaceBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accentLight : AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyPlayedView(
    List<Song> recentlyPlayed,
    Song? currentSong,
    bool isPlaying,
  ) {
    if (recentlyPlayed.isEmpty) {
      return _buildEmptyState(
        Icons.history_rounded,
        'No recently played tracks',
        subtitle: 'Start listening to songs to see your playback history',
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: recentlyPlayed.length + 1,
      itemBuilder: (context, index) {
        if (index == recentlyPlayed.length) return const SizedBox(height: 120);
        final song = recentlyPlayed[index];
        final isActive = currentSong?.identity == song.identity;
        return SongTile(
          song: song,
          isActive: isActive,
          isPlaying: isActive && isPlaying,
          onTap: () => _onSongTap(song),
          onFavoriteTap: () => widget.onFavoriteTap(song),
        );
      },
    );
  }

  Widget _buildLocalSongsView(
    List<Song> localSongs,
    Song? currentSong,
    bool isPlaying,
  ) {
    if (localSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.audio_file_outlined,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            const Text(
              'No local tracks found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Scan your storage to add on-device music files',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.audioService.scanLocalSongs,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Scan Storage'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: localSongs.length + 1,
      itemBuilder: (context, index) {
        if (index == localSongs.length) return const SizedBox(height: 120);
        final song = localSongs[index];
        final isActive = currentSong?.identity == song.identity;
        return SongTile(
          song: song,
          isActive: isActive,
          isPlaying: isActive && isPlaying,
          onTap: () => _onSongTap(song),
          onFavoriteTap: () => widget.onFavoriteTap(song),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message, {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'New Playlist',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                widget.onCreatePlaylist(name);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Create',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
