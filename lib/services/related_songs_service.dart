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
    int limit = 12,
  }) async {
    if (!_catalog.isAvailable) return const [];

    final cacheKey = currentSong.identity;
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (cached.isNotEmpty) {
        // Exclude songs already in the current queue
        final queueIds = (currentQueue ?? const [])
            .map((s) => s.videoId)
            .whereType<String>()
            .toSet();
        return cached.where((s) => !queueIds.contains(s.videoId)).toList();
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

    // 2. Song & Artist related songs query
    if (cleanedTitle.isNotEmpty &&
        cleanedArtist.isNotEmpty &&
        cleanedArtist.toLowerCase() != 'unknown channel') {
      searchQueries.add('$cleanedTitle $cleanedArtist songs');
    } else if (cleanedTitle.isNotEmpty) {
      searchQueries.add('$cleanedTitle related songs');
    }

    // 3. Artist popular songs query (for variety & language consistency)
    if (cleanedArtist.isNotEmpty &&
        cleanedArtist.toLowerCase() != 'unknown channel') {
      searchQueries.add('$cleanedArtist songs');
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
            candidateVideos.add(video);
            if (candidateVideos.length >= limit) break;
          }
        }
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

  /// Filters out non-music videos (e.g. trailers, interviews, podcasts, clips)
  bool _isValidRelatedVideo(YoutubeVideo video, Song currentSong) {
    if (video.id == currentSong.videoId) return false;

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
    int limit = 10,
  }) {
    final excludeIdentities = <String>{currentSong.identity};
    if (currentQueue != null) {
      for (final s in currentQueue) {
        excludeIdentities.add(s.identity);
      }
    }

    final pool = localSongs
        .where((s) => !excludeIdentities.contains(s.identity))
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
