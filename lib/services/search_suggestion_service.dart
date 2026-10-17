import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/song.dart';

enum SuggestionType {
  recent,
  library,
  online,
}

class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final Song? song;

  const SearchSuggestion({
    required this.text,
    required this.type,
    this.song,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSuggestion &&
          runtimeType == other.runtimeType &&
          text.toLowerCase() == other.text.toLowerCase();

  @override
  int get hashCode => text.toLowerCase().hashCode;
}

class SearchSuggestionService {
  static final SearchSuggestionService instance = SearchSuggestionService();

  final http.Client _client;
  final Map<String, List<String>> _cache = {};

  SearchSuggestionService({http.Client? client})
      : _client = client ?? http.Client();

  /// Fetches real-time song & query suggestions from YouTube's public completion endpoint.
  Future<List<String>> fetchOnlineSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final key = trimmed.toLowerCase();
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final uri = Uri.parse(
        'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=${Uri.encodeQueryComponent(trimmed)}',
      );
      final response = await _client
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.length > 1 && decoded[1] is List) {
          final rawList = decoded[1] as List;
          final suggestions = rawList
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .take(12)
              .toList();

          if (_cache.length > 150) {
            _cache.remove(_cache.keys.first);
          }
          _cache[key] = suggestions;
          return suggestions;
        }
      }
    } catch (_) {
      // Gracefully fall back on network interruption
    }
    return const [];
  }

  /// Combines matching recent searches, library songs, and online suggestions.
  Future<List<SearchSuggestion>> getCombinedSuggestions(
    String query, {
    List<Song> librarySongs = const [],
    List<String> recentSearches = const [],
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final lower = trimmed.toLowerCase();

    final results = <SearchSuggestion>[];
    final seen = <String>{};

    // 1. Matching recent searches
    for (final recent in recentSearches) {
      final rTrim = recent.trim();
      if (rTrim.toLowerCase().contains(lower) && seen.add(rTrim.toLowerCase())) {
        results.add(
          SearchSuggestion(text: rTrim, type: SuggestionType.recent),
        );
      }
    }

    // 2. Matching library & catalog songs (title or artist)
    for (final song in librarySongs) {
      final titleLower = song.title.toLowerCase();
      final artistLower = song.artist.toLowerCase();
      if (titleLower.contains(lower) || artistLower.contains(lower)) {
        if (seen.add(song.title.toLowerCase())) {
          results.add(
            SearchSuggestion(
              text: song.title,
              type: SuggestionType.library,
              song: song,
            ),
          );
        }
      }
    }

    // 3. Online suggestions from YouTube / Internet
    final online = await fetchOnlineSuggestions(trimmed);
    for (final item in online) {
      if (seen.add(item.toLowerCase())) {
        results.add(
          SearchSuggestion(text: item, type: SuggestionType.online),
        );
      }
    }

    return results;
  }
}
