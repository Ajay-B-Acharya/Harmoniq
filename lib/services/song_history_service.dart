import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';
import '../models/song.dart';
import '../models/song_history_entry.dart';
import 'profile_service.dart';

/// Service managing individual user playback history synced with Supabase.
/// Allows querying, recording, and clearing history per authenticated user ID.
class SongHistoryService extends ChangeNotifier {
  SongHistoryService._();
  static final SongHistoryService instance = SongHistoryService._();

  SupabaseClient? _client;
  SupabaseClient? get client {
    if (_client != null) return _client;
    try {
      return SupabaseConfig.client;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  void setClient(SupabaseClient? c) {
    _client = c;
  }

  /// Records a playback event to Supabase for the authenticated [userId].
  Future<void> recordSongPlayback({
    required String userId,
    required Song song,
  }) async {
    final c = client;

    // Cache locally first
    await _prependLocalCachedHistory(userId, song);

    // Also update listening time in profile
    final seconds = song.duration.inSeconds > 0 ? song.duration.inSeconds : 180;
    ProfileService.instance.addListeningSeconds(userId, seconds);

    if (c == null) return;

    try {
      await c.from('song_history').insert({
        'user_id': userId,
        'song_id': song.identity,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'duration_seconds': song.duration.inSeconds,
        'art_url': song.albumArtUrl,
        'source': song.source.name,
        'played_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SONG_HISTORY] Error recording song playback to Supabase: $e');
    }
  }

  /// Fetches the individual user's song history from Supabase, falling back to local cache.
  Future<List<SongHistoryEntry>> fetchUserHistory({
    required String userId,
    int limit = 50,
  }) async {
    final c = client;

    final cached = await _loadLocalCachedHistory(userId);

    if (c == null) {
      return cached;
    }

    try {
      final res = await c
          .from('song_history')
          .select()
          .eq('user_id', userId)
          .order('played_at', ascending: false)
          .limit(limit);

      final list = (res as List)
          .map((row) => SongHistoryEntry.fromJson(row as Map<String, dynamic>))
          .toList();

      await _saveLocalCachedHistory(userId, list);
      return list;
    } catch (e) {
      debugPrint('[SONG_HISTORY] Error fetching user history from Supabase: $e');
      return cached;
    }
  }

  /// Clears all history for the given [userId] both remotely and locally.
  Future<void> clearUserHistory({required String userId}) async {
    await _clearLocalCachedHistory(userId);
    notifyListeners();

    final c = client;
    if (c == null) return;

    try {
      await c.from('song_history').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('[SONG_HISTORY] Error clearing user history from Supabase: $e');
    }
  }

  // ── Local User History Cache ───────────────────────────────────────────────

  String _cacheKey(String userId) => 'harmoniq_history_user_$userId';

  Future<List<SongHistoryEntry>> _loadLocalCachedHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_cacheKey(userId)) ?? [];
      return list.map((str) {
        final map = json.decode(str) as Map<String, dynamic>;
        return SongHistoryEntry.fromJson(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalCachedHistory(
    String userId,
    List<SongHistoryEntry> entries,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = entries.take(50).map((e) => json.encode(e.toJson())).toList();
      await prefs.setStringList(_cacheKey(userId), list);
    } catch (_) {}
  }

  Future<void> _prependLocalCachedHistory(String userId, Song song) async {
    try {
      final current = await _loadLocalCachedHistory(userId);
      current.removeWhere((item) => item.songId == song.identity);
      final newEntry = SongHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        songId: song.identity,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
        artUrl: song.albumArtUrl,
        source: song.source.name,
        playedAt: DateTime.now().toUtc(),
      );
      current.insert(0, newEntry);
      await _saveLocalCachedHistory(userId, current);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _clearLocalCachedHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey(userId));
    } catch (_) {}
  }
}
