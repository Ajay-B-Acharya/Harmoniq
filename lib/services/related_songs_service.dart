import 'dart:async';
import 'dart:math';

import '../models/song.dart';
import '../models/youtube_video.dart';
import 'youtube_catalog.dart';

/// Service that discovers contextually related songs (same movie/soundtrack,
/// same artist, or similar language/genre) like YouTube autoplay/radio.
class RelatedSongsService {
  static final RelatedSongsService instance = RelatedSongsService();

  final YoutubeCatalog _catalog;
  final Random _random;
  final Map<String, List<Song>> _cache = {};

  RelatedSongsService({
    YoutubeCatalog? catalog,
    Random? random,
  }) : _catalog = catalog ?? YoutubeCatalog.instance,
       _random = random ?? Random();

  /// Removes common YouTube music video noise, tags, and decorators from titles.
  static String cleanTitle(String raw) {
    var title = raw;

    // Strip bracketed or parenthesized tags like (Official Video), [4K UHD], (From "Movie"), etc.
    title = title.replaceAll(
      RegExp(
        r'\s*[\(\[][^\)\]]*(?:official|video|audio|lyric|4k|hd|remaster|visualizer|version|teaser|trailer|from|feat|ft\.)[^\)\]]*[\)\]]',
        caseSensitive: false,
      ),
      '',
    );

    // Strip common standalone phrases
    title = title.replaceAll(
      RegExp(
        r'\b(?:official\s*(?:music\s*)?video|official\s*audio|full\s*song|video\s*song|4k\s*uhd|hd\s*video|lyrical\s*video)\b',
        caseSensitive: false,
      ),
      '',
    );

    // If there's pipe or dash separation (e.g. "Kesariya - Brahmastra | Ranbir Kapoor | Pritam")
    final segments = title.split(RegExp(r'[\-|•|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      // The first segment is almost universally the actual song title
      title = segments.first;
    }

    // Clean up surrounding punctuation & whitespace
    title = title
        .replaceAll(RegExp(r'[\s\-_|:]+$'), '')
        .replaceAll(RegExp(r'^[\s\-_|:]+'), '')
        .trim();

    return title.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Returns a canonical lowercase string representing the song's title for deduplication.
  static String normalizeTitle(String raw) => cleanTitle(raw).trim().toLowerCase();

  /// Identifies generic record label and corporate channel names on YouTube.
  static bool isRecordLabel(String raw) {
    final lower = raw.toLowerCase();
    const labels = [
      't-series',
      'tseries',
      'sony music',
      'zee music',
      'yrf',
      'saregama',
      'tips official',
      'tips music',
      'speed records',
      'aditya music',
      'lahari music',
      'eros now',
      'think music',
      'geetha arts',
      'svf',
      'soundtrack',
      'vevo',
      'records',
      'music channel',
    ];
    return labels.any((l) => lower.contains(l));
  }

  /// Cleans artist/channel names (strips "- Topic", "VEVO", "Official", etc.)
  static String cleanArtist(String raw) {
    var artist = raw.trim();
    artist = artist.replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '');
    artist = artist.replaceAll(RegExp(r'\s*VEVO$', caseSensitive: false), '');
    artist = artist.replaceAll(RegExp(r'\s*Official\s*(?:Artist\s*)?(?:Channel)?$', caseSensitive: false), '');
    return artist.trim();
  }

  /// Attempts to extract the movie or album name from the song title or metadata.
  static String? extractMovieOrAlbum(Song song) {
    if (song.album.isNotEmpty &&
        song.album.toLowerCase() != 'youtube' &&
        song.album.toLowerCase() != 'unknown album') {
      return song.album;
    }

    final raw = song.title;

    // Pattern 1: (From "Movie Name") or [From 'Movie Name']
    final quotedFrom = RegExp(
      r'from\s+["\x27]([^"\x27]+)["\x27]',
      caseSensitive: false,
    ).firstMatch(raw);
    if (quotedFrom != null) {
      final match = quotedFrom.group(1)?.trim();
      if (match != null && match.isNotEmpty) return match;
    }

    // Pattern 2: (From Movie Name)
    final unquotedFrom = RegExp(
      r'from\s+([A-Za-z0-9\s]+?)(?:[\)\]|]|$)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (unquotedFrom != null) {
      final match = unquotedFrom.group(1)?.trim();
      if (match != null && match.isNotEmpty && match.length < 35) return match;
    }

    // Pattern 3: "Song Title - Movie Name | ..." or "Song Title | Movie Name | ..."
    final parts = raw.split(RegExp(r'[\-|•|]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final candidate = parts[1];
      final lower = candidate.toLowerCase();
      // Verify candidate is likely a movie/album and not an actor/singer list
      if (!lower.contains('official') &&
          !lower.contains('video') &&
          !lower.contains('audio') &&
          !lower.contains('feat') &&
          candidate.length <= 40) {
        return candidate;
      }
    }

    return null;
  }

  /// Discovers related songs on YouTube based on the currently playing track.
  /// Looks for:
  /// 1. Other songs from the same movie/album (e.g. "Brahmastra songs")
  /// 2. Songs by the same artist or related singers/composers (e.g. "Kesariya Arijit Singh")
  /// 3. Songs in the same language / genre
  Future<List<Song>> findRelatedSongs(
    Song currentSong, {
    List<Song>? currentQueue,
    bool Function(Song)? isExcluded,
    int limit = 12,
  }) async {
    if (!_catalog.isAvailable) return const [];

    final cacheKey = currentSong.identity;
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (cached.isNotEmpty) {
        // Exclude songs already in the current queue and excluded/played songs
        final queueIds = (currentQueue ?? const [])
            .map((s) => s.videoId)
            .whereType<String>()
            .toSet();
        return cached
            .where((s) =>
                !queueIds.contains(s.videoId) &&
                (isExcluded == null || !isExcluded(s)))
            .toList();
      }
    }

    final excludeIds = <String>{};
    if (currentSong.videoId != null) excludeIds.add(currentSong.videoId!);
    if (currentQueue != null) {
      for (final s in currentQueue) {
        if (s.videoId != null) excludeIds.add(s.videoId!);
      }
    }

    final cleanedTitle = cleanTitle(currentSong.title);
    final cleanedArtist = cleanArtist(currentSong.artist);
    final movieOrAlbum = extractMovieOrAlbum(currentSong);

    final searchQueries = <String>[];

    // 1. Movie / Album soundtrack query (highest affinity)
    if (movieOrAlbum != null &&
        movieOrAlbum.isNotEmpty &&
        movieOrAlbum.toLowerCase() != cleanedTitle.toLowerCase()) {
      searchQueries.add('$movieOrAlbum songs');
    }

    final isLabel = isRecordLabel(cleanedArtist);

    // 2. Song & Artist related songs query
    if (cleanedTitle.isNotEmpty &&
        !isLabel &&
        cleanedArtist.isNotEmpty &&
        cleanedArtist.toLowerCase() != 'unknown channel') {
      searchQueries.add('$cleanedTitle $cleanedArtist');
      searchQueries.add('$cleanedArtist songs');
    } else if (cleanedTitle.isNotEmpty) {
      searchQueries.add('$cleanedTitle songs');
    }

    // 3. If movieOrAlbum was not found, try searching the song title with 'songs'
    if (movieOrAlbum == null && cleanedTitle.isNotEmpty && !searchQueries.contains('$cleanedTitle songs')) {
      searchQueries.add('$cleanedTitle songs');
    }

    // Fallback query if title was too short or empty
    if (searchQueries.isEmpty) {
      searchQueries.add(
        cleanedTitle.isNotEmpty ? '$cleanedTitle songs' : 'popular songs',
      );
    }

    final candidateVideos = <YoutubeVideo>[];
    final seenIds = Set<String>.from(excludeIds);

    for (final query in searchQueries) {
      if (candidateVideos.length >= limit) break;
      try {
        final videos = await _catalog.search(query, page: 1);
        for (final video in videos) {
          if (seenIds.add(video.id) && _isValidRelatedVideo(video, currentSong)) {
            final song = Song.fromYoutube(video);
            if (isExcluded != null && isExcluded(song)) continue;
            candidateVideos.add(video);
            if (candidateVideos.length >= limit) break;
          }
        }
        // If we found at least 5 strong related candidates from the primary query,
        // stop here to keep autoplay discovery instant without blocking on further queries.
        if (candidateVideos.length >= 6) break;
      } catch (_) {
        // If one query fails, continue to the next
      }
    }

    final resultSongs = candidateVideos.map(Song.fromYoutube).toList();

    // Cache the discovered related songs
    if (resultSongs.isNotEmpty) {
      if (_cache.length > 50) {
        _cache.remove(_cache.keys.first);
      }
      _cache[cacheKey] = resultSongs;
    }

    return resultSongs;
  }

  /// Discovers continuous music for explore/radio mode.
  /// Combines related songs with trending/discovery tracks like YouTube autoplay radio,
  /// ensuring an endless variety of music while excluding previously played songs.
  Future<List<Song>> findExploreRadioSongs({
    required Song currentSong,
    List<Song>? currentQueue,
    bool Function(Song)? isExcluded,
    int limit = 10,
  }) async {
    final results = <Song>[];
    final seenIds = <String>{};

    bool isAllowed(Song song) {
      if (song.videoId != null && seenIds.contains(song.videoId)) return false;
      if (currentSong.videoId != null && song.videoId == currentSong.videoId) return false;
      if (isExcluded != null && isExcluded(song)) return false;
      if (currentQueue != null) {
        for (final q in currentQueue) {
          if (q.identity == song.identity) return false;
          if (q.videoId != null && song.videoId != null && q.videoId == song.videoId) return false;
          final qNorm = normalizeTitle(q.title);
          final sNorm = normalizeTitle(song.title);
          if (qNorm.isNotEmpty && qNorm == sNorm) return false;
        }
      }
      return true;
    }

    // 1. Fetch related songs first (highest affinity: same movie, soundtrack, artist)
    try {
      final related = await findRelatedSongs(
        currentSong,
        currentQueue: currentQueue,
        isExcluded: isExcluded,
        limit: limit,
      );
      for (final song in related) {
        if (isAllowed(song)) {
          if (song.videoId != null) seenIds.add(song.videoId!);
          results.add(song);
          if (results.length >= limit) return results;
        }
      }
    } catch (_) {}

    // 2. Proactively augment with public discovery / trending tracks from YouTube
    if (results.length < limit && _catalog.isAvailable) {
      try {
        final discoverVideos = await _catalog.discover();
        for (final v in discoverVideos) {
          final song = Song.fromYoutube(v);
          if (isAllowed(song) && _isValidRelatedVideo(v, currentSong)) {
            if (song.videoId != null) seenIds.add(song.videoId!);
            results.add(song);
            if (results.length >= limit) return results;
          }
        }
      } catch (_) {}
    }

    // 3. Fallback: Search diverse YouTube music categories to ensure infinite music
    if (results.length < limit && _catalog.isAvailable) {
      const vibes = [
        'top music hits',
        'viral songs',
        'trending music',
        'popular songs',
        'bollywood hits',
        'global top songs',
      ];
      final query = vibes[_random.nextInt(vibes.length)];
      try {
        final videos = await _catalog.search(query, page: 1);
        for (final v in videos) {
          final song = Song.fromYoutube(v);
          if (isAllowed(song) && _isValidRelatedVideo(v, currentSong)) {
            if (song.videoId != null) seenIds.add(song.videoId!);
            results.add(song);
            if (results.length >= limit) return results;
          }
        }
      } catch (_) {}
    }

    return results;
  }

  /// Filters out non-music videos (e.g. trailers, interviews, podcasts, clips)
  bool _isValidRelatedVideo(YoutubeVideo video, Song currentSong) {
    if (video.id == currentSong.videoId) return false;

    // Filter out re-uploads/duplicate versions of the exact same song
    final currentClean = cleanTitle(currentSong.title).toLowerCase();
    final vidClean = cleanTitle(video.title).toLowerCase();
    if (currentClean.isNotEmpty && currentClean == vidClean) {
      return false;
    }

    final lowerTitle = video.title.toLowerCase();
    const blacklist = [
      'trailer',
      'teaser',
      'interview',
      'behind the scenes',
      'making of',
      'reaction',
      'review',
      'podcast',
      'episode',
      'full movie',
      'funny scene',
      'comedy scene',
      'dialogue',
      'scene',
      '1 hour loop',
      '10 hours',
      '1 hour',
    ];

    for (final term in blacklist) {
      if (lowerTitle.contains(term)) return false;
    }

    // Duration filter: music tracks typically run between 45 seconds and 15 minutes
    if (video.duration > Duration.zero) {
      if (video.duration < const Duration(seconds: 45) ||
          video.duration > const Duration(minutes: 15)) {
        return false;
      }
    }

    return true;
  }

  /// Discovers related songs from local music (by same album, artist, or library shuffle)
  List<Song> findRelatedLocalSongs(
    Song currentSong,
    List<Song> localSongs, {
    List<Song>? currentQueue,
    bool Function(Song)? isExcluded,
    int limit = 10,
  }) {
    final excludeIdentities = <String>{currentSong.identity};
    if (currentQueue != null) {
      for (final s in currentQueue) {
        excludeIdentities.add(s.identity);
      }
    }

    final pool = localSongs
        .where((s) =>
            !excludeIdentities.contains(s.identity) &&
            (isExcluded == null || !isExcluded(s)))
        .toList();
    if (pool.isEmpty) return const [];

    final sameAlbum = pool
        .where(
          (s) =>
              s.album.isNotEmpty &&
              s.album.toLowerCase() == currentSong.album.toLowerCase(),
        )
        .toList();

    final sameArtist = pool
        .where(
          (s) =>
              s.artist.isNotEmpty &&
              s.artist.toLowerCase() == currentSong.artist.toLowerCase() &&
              !sameAlbum.contains(s),
        )
        .toList();

    final remaining = pool
        .where((s) => !sameAlbum.contains(s) && !sameArtist.contains(s))
        .toList()
      ..shuffle(_random);

    final combined = <Song>[
      ...sameAlbum,
      ...sameArtist,
      ...remaining,
    ];

    return combined.take(limit).toList();
  }
}
