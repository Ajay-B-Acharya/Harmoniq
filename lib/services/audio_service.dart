import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart' show MediaItem;
import 'harmoniq_audio_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'power_manager_service.dart';
import 'song_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../models/playlist.dart';
import '../data/sample_data.dart';
import 'playback_failure.dart';
import 'related_songs_service.dart';
import 'youtube_audio_stream_resolver.dart' as youtube;
import 'yt_dlp_channel.dart';

class AudioService extends ChangeNotifier {
  // ── Song registry ──────────────────────────────────────────────────────────
  final List<Song> _songs = [];
  final Map<String, int> _songIndices = {};
  List<Song> get songs => _songs;

  // Lists retain their identity, so consumers must invalidate derived caches
  // using these revisions rather than list identity or playback notifications.
  int _catalogRevision = 0;
  int get catalogRevision => _catalogRevision;
  int _localSongsRevision = 0;
  int get localSongsRevision => _localSongsRevision;
  bool _disposed = false;
  Future<void>? _scanFuture;

  late List<Playlist> _playlists;
  List<Playlist> get playlists => _playlists;

  // ── Persistent Favorites ──────────────────────────────────────────────────────
  static const String _prefsKeyFavorites = 'harmoniq_favorites_v1';
  List<Song> _favorites = [];
  List<Song> get favorites => _favorites;

  // ── Persistent Recently Played ────────────────────────────────────────────────
  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  static const String _prefsKeyRecentlyPlayed = 'harmoniq_recently_played_v1';
  List<Song> _recentlyPlayed = [];
  List<Song> get recentlyPlayed => _recentlyPlayed;

  // ── Persistent Downloaded Songs ──────────────────────────────────────────────
  static const String _prefsKeyDownloads = 'harmoniq_downloads_v1';
  final List<Song> _downloadedSongs = [];
  List<Song> get downloadedSongs => _downloadedSongs;
  int _downloadsRevision = 0;
  int get downloadsRevision => _downloadsRevision;

  // ── Persistent Cached Local Songs ───────────────────────────────────────────
  static const String _prefsKeyLocalSongs = 'harmoniq_cached_local_songs_v1';

  List<Song> get allAvailableSongs {
    final seen = <String>{};
    final result = <Song>[];
    final base = [
      ..._downloadedSongs,
      ..._localSongs,
      ..._songs,
      ..._favorites,
      ..._recentlyPlayed,
    ];
    final source = base.isNotEmpty ? base : SampleData.songs;
    for (final s in source) {
      if (seen.add(s.identity)) {
        result.add(s);
      }
    }
    return result;
  }

  // ── Local storage scanning ───────────────────────────────────────────────────
  static const _platform = MethodChannel('com.example.harmoniq/local_music');
  List<Song> _localSongs = [];
  List<Song> get localSongs => _localSongs;
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  static const String prefAudioQualityKey = 'pref_audio_quality';
  String _audioQuality = 'High';
  String get audioQuality => _audioQuality;

  final AudioPlayer _player;
  final HarmoniqAudioHandler? _audioHandler;
  final Future<YoutubeAudioStream> Function(String videoId, {String? quality})
      _resolveYoutubeAudio;
  final Future<List<Song>> Function(
    Song currentSong, {
    List<Song>? currentQueue,
    int limit,
  })? _findRelatedSongs;

  // Pre-resolved stream cache for instant next track playback
  final Map<String, _PreloadedStream> _preloadedStreams = {};
  String? _preloadingVideoId;
  bool _fetchingRelatedSongs = false;
  bool _autoQueueRelated = false;
  bool get autoQueueRelated => _autoQueueRelated;

  bool _continuousDiscovery = false;
  bool get continuousDiscovery => _continuousDiscovery;
  void setContinuousDiscovery(bool enabled) {
    _continuousDiscovery = enabled;
    if (enabled && !_autoQueueRelated) {
      _autoQueueRelated = true;
    }
    notifyListeners();
  }

  // Played tracks tracking to guarantee no repetitive songs during playback
  final Set<String> _playedSongIdentities = <String>{};
  final Set<String> _playedVideoIds = <String>{};
  final Set<String> _playedTitles = <String>{};

  void _markSongAsPlayed(Song song) {
    _playedSongIdentities.add(song.identity);
    if (song.videoId != null && song.videoId!.isNotEmpty) {
      _playedVideoIds.add(song.videoId!);
    }
    final normalized = RelatedSongsService.normalizeTitle(song.title);
    if (normalized.isNotEmpty) {
      _playedTitles.add(normalized);
    }
  }

  /// Checks if a song has already been played in this session or recently
  bool hasSongBeenPlayed(Song song) {
    if (_playedSongIdentities.contains(song.identity)) return true;
    if (song.videoId != null &&
        song.videoId!.isNotEmpty &&
        _playedVideoIds.contains(song.videoId!)) {
      return true;
    }
    final normalized = RelatedSongsService.normalizeTitle(song.title);
    if (normalized.isNotEmpty && _playedTitles.contains(normalized)) {
      return true;
    }
    for (final recent in _recentlyPlayed) {
      if (recent.identity == song.identity) return true;
      if (recent.videoId != null &&
          song.videoId != null &&
          recent.videoId == song.videoId) {
        return true;
      }
    }
    return false;
  }

  int get _remainingQueueCount {
    if (_queue.isEmpty || _currentQueueIndex < 0) return 0;
    return _queue.length - 1 - _currentQueueIndex;
  }
  Future<void> _playerMutations = Future<void>.value();
  int _generation = 0;
  int? _readyGeneration;
  bool _retryAttempted = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _playbackError;
  String? get playbackError => _playbackError;
  bool _wantsToPlay = false;
  bool get wantsToPlay => _wantsToPlay;
  bool get canSeek =>
      !_disposed &&
      _currentSong != null &&
      !_isLoading &&
      _playbackError == null &&
      (_isSimulated(_currentSong!) || _readyGeneration == _generation);

  // ── Playback state (driven by the real player) ───────────────────────────────
  Song? _currentSong;
  Song? get currentSong => _currentSong;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _playbackPosition = Duration.zero;
  Duration get playbackPosition => _playbackPosition;

  // Dedicated notifier for 60fps seek bar updates without rebuilding main screens
  final ValueNotifier<Duration> playbackPositionNotifier =
      ValueNotifier<Duration>(Duration.zero);

  bool _shuffleEnabled = false;
  bool get shuffleEnabled => _shuffleEnabled;

  bool _repeatEnabled = false;
  bool get repeatEnabled => _repeatEnabled;

  List<Song> _queue = [];
  List<Song> get queue => UnmodifiableListView(_queue);

  int _currentQueueIndex = -1;
  int get currentQueueIndex => _currentQueueIndex;

  int _manualQueueCount = 0;
  int get manualQueueCount => _manualQueueCount;

  // ── Subscriptions ─────────────────────────────────────────────────────────────
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _playerCompleteSub;
  StreamSubscription<PlaybackEvent>? _playbackErrorSub;

  AudioService({
    Future<Uri> Function(String videoId)? resolveYoutubeAudio,
    Function? resolveYoutubeStream,
    AudioPlayer? audioPlayer,
    this._findRelatedSongs,
    HarmoniqAudioHandler? audioHandler,
  }) : _player = audioPlayer ?? AudioPlayer(),
       _audioHandler = audioHandler ?? HarmoniqAudioHandler.instance,
       _resolveYoutubeAudio = _wrapResolver(
         resolveYoutubeStream: resolveYoutubeStream,
         resolveYoutubeAudio: resolveYoutubeAudio,
       ) {
    _playlists = [
      Playlist(id: 0, name: "Favorites", songs: [], gradientId: 0),
      Playlist(id: 1, name: "Chill Vibes", songs: [], gradientId: 1),
      Playlist(id: 2, name: "Workout", songs: [], gradientId: 5),
      Playlist(id: 3, name: "Focus & Flow", songs: [], gradientId: 7),
    ];

    _attachPlayerListeners();
    _loadFavorites();
    _loadRecentlyPlayed();
    _loadDownloads();
    _loadCachedLocalSongs();
    _loadAudioQuality();
    _initAudioSession();
    autoScanIfPermitted();
    _audioHandler?.attachAudioService(this);
  }

  /// Expose the underlying YouTube audio stream resolver for authorized downloads.
  Future<YoutubeAudioStream> resolveYoutubeStream(
    String videoId, {
    String? quality,
  }) => _resolveYoutubeAudio(videoId, quality: quality ?? _audioQuality);

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] AudioSession configure notice: $e');
    }
  }

  Future<void> _loadAudioQuality() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      _audioQuality = prefs.getString(prefAudioQualityKey) ?? 'High';
      notifyListeners();
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error loading audio quality preference: $e');
    }
  }

  Future<void> setAudioQuality(String quality) async {
    if (_audioQuality == quality) return;
    _audioQuality = quality;
    _preloadedStreams.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefAudioQualityKey, quality);
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error saving audio quality preference: $e');
    }
    notifyListeners();

    // If currently playing or loading an online YouTube song, seamlessly reload
    // at the newly selected stream quality while preserving the current playback position.
    final current = _currentSong;
    if (!_disposed &&
        current != null &&
        current.source == SongSource.youtube &&
        _canPlay(current)) {
      await _selectSong(
        current,
        resumeAt: _playbackPosition,
        wantsToPlay: _wantsToPlay,
      );
    } else {
      _preloadNextTrack();
    }
  }

  static Future<YoutubeAudioStream> Function(String videoId, {String? quality})
      _wrapResolver({
    Function? resolveYoutubeStream,
    Future<Uri> Function(String videoId)? resolveYoutubeAudio,
  }) {
    if (resolveYoutubeStream != null) {
      if (resolveYoutubeStream
          is Future<YoutubeAudioStream> Function(String, {String? quality})) {
        return resolveYoutubeStream;
      }
      if (resolveYoutubeStream is Future<YoutubeAudioStream> Function(String)) {
        return (id, {quality}) => resolveYoutubeStream(id);
      }
      return (id, {quality}) async {
        try {
          return await Function.apply(
            resolveYoutubeStream,
            [id],
            {#quality: quality},
          ) as YoutubeAudioStream;
        } catch (_) {
          return await Function.apply(resolveYoutubeStream, [id])
              as YoutubeAudioStream;
        }
      };
    }
    if (resolveYoutubeAudio != null) {
      return (id, {quality}) async =>
          YoutubeAudioStream(await resolveYoutubeAudio(id));
    }
    return youtube.resolveYoutubeStream;
  }

  // ── Persistent Favorites Loading & Saving ────────────────────────────────────
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      final jsonList = prefs.getStringList(_prefsKeyFavorites) ?? [];
      _favorites = jsonList.map((str) {
        final map = json.decode(str) as Map<String, dynamic>;
        return Song.fromJson(map).copyWith(isFavorite: true);
      }).toList();

      // Sync Favorites playlist
      final favPlaylist = _playlists.firstWhere((p) => p.id == 0);
      favPlaylist.songs.clear();
      favPlaylist.songs.addAll(_favorites);

      _syncFavoriteStates();
      notifyListeners();
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _favorites.map((s) => json.encode(s.toJson())).toList();
      await prefs.setStringList(_prefsKeyFavorites, jsonList);
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error saving favorites: $e');
    }
  }

  // ── Persistent Recently Played Loading & Saving ─────────────────────────────
  Future<void> _loadRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      final jsonList = prefs.getStringList(_prefsKeyRecentlyPlayed) ?? [];
      _recentlyPlayed = jsonList.map((str) {
        final map = json.decode(str) as Map<String, dynamic>;
        return Song.fromJson(map);
      }).toList();
      for (final s in _recentlyPlayed) {
        _markSongAsPlayed(s);
      }
      _syncFavoriteStates();
      notifyListeners();
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error loading recently played: $e');
    }
  }

  Future<void> _saveRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList =
          _recentlyPlayed.take(30).map((s) => json.encode(s.toJson())).toList();
      await prefs.setStringList(_prefsKeyRecentlyPlayed, jsonList);
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error saving recently played: $e');
    }
  }

  void setUserId(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    if (userId != null && userId.isNotEmpty) {
      _loadUserHistoryFromSupabase(userId);
    } else {
      _loadRecentlyPlayed();
    }
  }

  Future<void> _loadUserHistoryFromSupabase(String userId) async {
    try {
      final entries =
          await SongHistoryService.instance.fetchUserHistory(userId: userId);
      if (_disposed) return;
      if (entries.isNotEmpty) {
        _recentlyPlayed = entries.map((e) => e.toSong()).toList();
        for (final s in _recentlyPlayed) {
          _markSongAsPlayed(s);
        }
        _syncFavoriteStates();
        notifyListeners();
      } else {
        await _loadRecentlyPlayed();
      }
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error loading Supabase history: $e');
      await _loadRecentlyPlayed();
    }
  }

  Future<void> clearHistory() async {
    final uid = _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      await SongHistoryService.instance.clearUserHistory(userId: uid);
    }
    _recentlyPlayed.clear();
    _playedSongIdentities.clear();
    _playedVideoIds.clear();
    _playedTitles.clear();
    if (_currentSong != null) {
      _markSongAsPlayed(_currentSong!);
    }
    await _saveRecentlyPlayed();
    notifyListeners();
  }

  void _recordRecentlyPlayed(Song song) {
    _recentlyPlayed.removeWhere((s) => s.identity == song.identity);
    _recentlyPlayed.insert(0, song.copyWith(isFavorite: isSongFavorite(song)));
    if (_recentlyPlayed.length > 30) {
      _recentlyPlayed.removeLast();
    }
    _saveRecentlyPlayed();

    final uid = _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      SongHistoryService.instance.recordSongPlayback(
        userId: uid,
        song: song,
      );
    }
  }

  bool isSongFavorite(Song song) =>
      _favorites.any((s) => s.identity == song.identity);

  void _syncFavoriteStates() {
    final favIds = _favorites.map((s) => s.identity).toSet();

    for (int i = 0; i < _songs.length; i++) {
      _songs[i] = _songs[i].copyWith(
        isFavorite: favIds.contains(_songs[i].identity),
      );
    }
    for (int i = 0; i < _localSongs.length; i++) {
      _localSongs[i] = _localSongs[i].copyWith(
        isFavorite: favIds.contains(_localSongs[i].identity),
      );
    }
    for (int i = 0; i < _queue.length; i++) {
      _queue[i] = _queue[i].copyWith(
        isFavorite: favIds.contains(_queue[i].identity),
      );
    }
    if (_currentSong != null) {
      _currentSong = _currentSong!.copyWith(
        isFavorite: favIds.contains(_currentSong!.identity),
      );
    }
    for (int i = 0; i < _recentlyPlayed.length; i++) {
      _recentlyPlayed[i] = _recentlyPlayed[i].copyWith(
        isFavorite: favIds.contains(_recentlyPlayed[i].identity),
      );
    }
    for (int i = 0; i < _downloadedSongs.length; i++) {
      _downloadedSongs[i] = _downloadedSongs[i].copyWith(
        isFavorite: favIds.contains(_downloadedSongs[i].identity),
      );
    }
    for (final playlist in _playlists.where((p) => p.id != 0)) {
      for (var i = 0; i < playlist.songs.length; i++) {
        final song = playlist.songs[i];
        playlist.songs[i] = song.copyWith(
          isFavorite: favIds.contains(song.identity),
        );
      }
    }

    _catalogRevision++;
    _localSongsRevision++;
    _downloadsRevision++;

    // Sync playlist #0 (Favorites)
    final favPlaylist = _playlists.firstWhere((p) => p.id == 0);
    favPlaylist.songs.clear();
    favPlaylist.songs.addAll(_favorites);
  }

  // ── Persistent Downloaded Songs Loading & Saving ─────────────────────────────
  Future<void>? _downloadsInitFuture;

  Future<void> _loadDownloads() async {
    _downloadsInitFuture ??= _doLoadDownloads();
    return _downloadsInitFuture;
  }

  Future<void> _doLoadDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      final jsonList = prefs.getStringList(_prefsKeyDownloads) ?? [];
      final loaded = jsonList.map((str) {
        final map = json.decode(str) as Map<String, dynamic>;
        final song = Song.fromJson(map);
        return song.copyWith(isFavorite: isSongFavorite(song));
      }).toList();

      for (final s in loaded) {
        if (!_downloadedSongs.any((d) => d.identity == s.identity)) {
          _downloadedSongs.add(s);
        }
      }
      _downloadsRevision++;
      notifyListeners();
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error loading downloads: $e');
    }
  }

  Future<void> _saveDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList =
          _downloadedSongs.map((s) => json.encode(s.toJson())).toList();
      await prefs.setStringList(_prefsKeyDownloads, jsonList);
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error saving downloads: $e');
    }
  }

  // ── Persistent Cached Local Songs Loading & Saving ───────────────────────────
  Future<void> _loadCachedLocalSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      final jsonList = prefs.getStringList(_prefsKeyLocalSongs) ?? [];
      if (jsonList.isNotEmpty && _localSongs.isEmpty) {
        final favIds = _favorites.map((s) => s.identity).toSet();
        _localSongs = jsonList.map((str) {
          final map = json.decode(str) as Map<String, dynamic>;
          final song = Song.fromJson(map);
          return song.copyWith(isFavorite: favIds.contains(song.identity));
        }).toList();
        _localSongsRevision++;
        _registerSongs(_localSongs);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error loading cached local songs: $e');
    }
  }

  Future<void> _saveCachedLocalSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList =
          _localSongs.map((s) => json.encode(s.toJson())).toList();
      await prefs.setStringList(_prefsKeyLocalSongs, jsonList);
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Error saving cached local songs: $e');
    }
  }

  Future<void> addDownloadedSong(Song song) async {
    await _loadDownloads();
    // Avoid duplicate entries
    _downloadedSongs.removeWhere(
      (s) =>
          s.identity == song.identity ||
          (song.videoId != null && s.videoId == song.videoId) ||
          (song.audioPath.isNotEmpty && s.audioPath == song.audioPath),
    );
    final songWithFav = song.copyWith(isFavorite: isSongFavorite(song));
    _downloadedSongs.insert(0, songWithFav);
    _downloadsRevision++;
    _catalogRevision++;
    notifyListeners();
    await _saveDownloads();
  }

  Future<void> removeDownloadedSong(Song song) async {
    await _loadDownloads();
    _downloadedSongs.removeWhere(
      (s) =>
          s.identity == song.identity ||
          (song.videoId != null && s.videoId == song.videoId) ||
          (song.audioPath.isNotEmpty && s.audioPath == song.audioPath) ||
          (s.title.trim().toLowerCase() == song.title.trim().toLowerCase() &&
              s.artist.trim().toLowerCase() == song.artist.trim().toLowerCase()),
    );
    if (song.audioPath.isNotEmpty &&
        !song.audioPath.startsWith('content://') &&
        !song.audioPath.startsWith('simulated_') &&
        !song.audioPath.startsWith('asset://')) {
      try {
        final file = File(song.audioPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
    _downloadsRevision++;
    _catalogRevision++;
    notifyListeners();
    await _saveDownloads();
  }

  bool isSongDownloaded(Song song) {
    if (song.source == SongSource.local &&
        _downloadedSongs.any((s) => s.audioPath == song.audioPath && s.audioPath.isNotEmpty)) {
      return true;
    }
    return _downloadedSongs.any(
      (s) =>
          s.identity == song.identity ||
          (song.videoId != null && s.videoId == song.videoId) ||
          (s.title.trim().toLowerCase() == song.title.trim().toLowerCase() &&
              s.artist.trim().toLowerCase() == song.artist.trim().toLowerCase()),
    );
  }

  Song? getDownloadedSong(Song song) {
    for (final s in _downloadedSongs) {
      if (s.identity == song.identity ||
          (song.videoId != null && s.videoId == song.videoId) ||
          (song.audioPath.isNotEmpty && s.audioPath == song.audioPath) ||
          (s.title.trim().toLowerCase() == song.title.trim().toLowerCase() &&
              s.artist.trim().toLowerCase() == song.artist.trim().toLowerCase())) {
        return s;
      }
    }
    return null;
  }

  /// Register tracks in input order; later metadata for an identity wins.
  void registerSongs(List<Song> newSongs) {
    if (_disposed || newSongs.isEmpty) return;
    _registerSongs(newSongs);
    notifyListeners();
  }

  void _registerSongs(List<Song> newSongs) {
    final favIds = _favorites.map((s) => s.identity).toSet();
    for (final song in newSongs) {
      final idx = _songIndices[song.identity];
      final synced = song.copyWith(isFavorite: favIds.contains(song.identity));
      if (idx == null) {
        _songIndices[song.identity] = _songs.length;
        _songs.add(synced);
      } else {
        _songs[idx] = synced;
      }
    }
    _catalogRevision++;
  }

  // Player events have no source ID. Ignore them until the selected generation
  // has finished installing its source, including all stop/load transitions.
  bool get _acceptPlayerEvents => !_disposed && _readyGeneration == _generation;

  void _attachPlayerListeners() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!_acceptPlayerEvents) return;
      final loading =
          state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;
      if (state.playing != _isPlaying ||
          state.playing != _wantsToPlay ||
          loading != _isLoading) {
        if (state.playing) {
          PowerManagerService.instance.acquirePlaybackWakeLock();
        } else {
          PowerManagerService.instance.releasePlaybackWakeLock();
        }
        // Native notification controls/audio interruptions also change intent.
        _wantsToPlay = state.playing;
        _isPlaying = state.playing;
        _isLoading = loading;
        notifyListeners();
      }
    });
    _playbackErrorSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object error) {
        if (_acceptPlayerEvents) {
          unawaited(_handlePlaybackError(_generation, error));
        }
      },
    );
    _positionSub = _player.positionStream.listen((pos) {
      if (!_acceptPlayerEvents) return;
      _playbackPosition = pos;
      playbackPositionNotifier.value = pos;
      if (pos.inSeconds > 0 &&
          pos.inSeconds % 10 == 0 &&
          (_continuousDiscovery || _autoQueueRelated) &&
          !_fetchingRelatedSongs &&
          _remainingQueueCount <= 3 &&
          _currentSong != null) {
        unawaited(_fetchAndAppendRelatedSongs(_currentSong!));
      }
    });
    _playerCompleteSub = _player.processingStateStream
        .where((s) => s == ProcessingState.completed)
        .listen((_) {
          if (!_acceptPlayerEvents || !_wantsToPlay) return;
          if (_repeatEnabled) {
            unawaited(_restart(_generation));
          } else {
            unawaited(next());
          }
        });
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  // Only player mutations are serialized. A slow resolver never holds this lock.
  Future<void> _mutatePlayer(Future<void> Function() action) {
    final result = _playerMutations.then((_) => action());
    _playerMutations = result.catchError((Object _) {});
    return result;
  }

  bool _isSimulated(Song song) =>
      song.source == SongSource.local &&
      (song.audioPath.isEmpty || song.audioPath.startsWith('simulated_'));

  bool _canPlay(Song song) {
    if (song.source == SongSource.youtube) {
      return RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(song.videoId ?? '');
    }
    if (song.source != SongSource.local) return false;
    final path = song.audioPath;
    return _isSimulated(song) ||
        path.startsWith('content://') ||
        path.startsWith('file://') ||
        path.startsWith('/') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
  }

  /// Enqueues [song] to play immediately after the active song (or after
  /// previously queued "play next" tracks).
  void queueNext(Song song) {
    if (_disposed || !_canPlay(song)) return;
    _registerSongs([song]);

    if (_currentSong == null || _queue.isEmpty) {
      unawaited(playSong(song));
      return;
    }

    // If this song already exists after the current track, remove old instance
    final existingIdx = _queue.indexWhere((s) => s.identity == song.identity);
    if (existingIdx > _currentQueueIndex) {
      _queue.removeAt(existingIdx);
      if (existingIdx <= _currentQueueIndex + _manualQueueCount) {
        _manualQueueCount = (_manualQueueCount - 1).clamp(0, _queue.length);
      }
    }

    final insertIndex =
        (_currentQueueIndex + 1 + _manualQueueCount).clamp(0, _queue.length);
    _queue.insert(insertIndex, song);
    _manualQueueCount++;

    _preloadNextTrack();
    notifyListeners();
  }

  Future<void> playSong(
    Song song, {
    List<Song>? contextQueue,
    bool autoQueueRelated = false,
    bool continuousDiscovery = false,
  }) async {
    if (_disposed || !_canPlay(song)) return;
    _manualQueueCount = 0;
    _continuousDiscovery = continuousDiscovery;
    _autoQueueRelated = continuousDiscovery ||
        autoQueueRelated ||
        song.source == SongSource.youtube ||
        (contextQueue == null || contextQueue.length <= 1);
    _registerSongs([song]);
    if (contextQueue != null) {
      _queue = contextQueue.where(_canPlay).toList();
    }
    _currentQueueIndex = _queue.indexWhere((s) => s.identity == song.identity);
    if (_currentQueueIndex == -1) {
      _queue.add(song);
      _currentQueueIndex = _queue.length - 1;
    }
    await _selectSong(song);

    if (_continuousDiscovery || _autoQueueRelated) {
      unawaited(_fetchAndAppendRelatedSongs(song));
    }
  }

  /// Reorders the active playback queue to match the new sort order [newOrder],
  /// while keeping the currently playing track active at its new position.
  void reorderQueue(List<Song> newOrder) {
    if (_disposed || _queue.isEmpty) return;
    _manualQueueCount = 0;
    final current = _currentSong;
    if (current == null) {
      _queue = newOrder.where(_canPlay).toList();
      notifyListeners();
      return;
    }

    final newIndex = newOrder.indexWhere((s) => s.identity == current.identity);
    if (newIndex != -1) {
      _queue = newOrder.where(_canPlay).toList();
      _currentQueueIndex = newIndex;
      notifyListeners();
      _preloadNextTrack();
    }
  }

  Future<void> skipToIndex(int index) async {
    _manualQueueCount = 0;
    if (_disposed ||
        index < 0 ||
        index >= _queue.length ||
        index == _currentQueueIndex ||
        !_canPlay(_queue[index])) {
      return;
    }
    _currentQueueIndex = index;
    await _selectSong(_queue[index]);
  }

  Future<void> _selectSong(
    Song song, {
    Duration resumeAt = Duration.zero,
    bool retry = false,
    bool? wantsToPlay,
  }) async {
    final generation = ++_generation;
    _readyGeneration = null;
    _retryAttempted = retry;
    _currentSong = song.copyWith(isFavorite: isSongFavorite(song));
    _recordRecentlyPlayed(song);
    _markSongAsPlayed(song);
    _isPlaying = false;
    _wantsToPlay = wantsToPlay ?? !_isSimulated(song);
    _isLoading = !_isSimulated(song);
    _playbackError = null;
    _playbackPosition = resumeAt;
    playbackPositionNotifier.value = resumeAt;
    notifyListeners();

    // Stop the previous source immediately, even while resolution is pending.
    final stopped =
        _mutatePlayer(() async {
          if (_isCurrent(generation)) await _player.stop();
        }).catchError((Object error) {
          _failPlayback(generation, error: error);
        });
    var loadingSource = false;
    try {
      if (_isSimulated(song)) {
        await stopped;
        return;
      }
      final Uri uri;
      Map<String, String> headers = const {};
      if (song.source == SongSource.youtube) {
        YoutubeAudioStream? stream;
        final cached = _preloadedStreams[song.videoId];
        if (!retry && cached != null && cached.isValid(_audioQuality)) {
          stream = cached.stream;
        } else {
          stream = await _resolveYoutubeAudio(
            song.videoId!,
            quality: _audioQuality,
          ).timeout(const Duration(seconds: 20));
          if (!_isCurrent(generation)) return;
          _preloadedStreams[song.videoId!] = _PreloadedStream(
            stream: stream,
            quality: _audioQuality,
            resolvedAt: DateTime.now(),
          );
        }
        uri = stream.uri;
        headers = stream.headers;
        if (uri.scheme != 'https' ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty) {
          throw StateError('Invalid audio stream.');
        }
      } else {
        final path = song.audioPath;
        uri = path.startsWith('content://') || path.startsWith('file://')
            ? Uri.parse(path)
            : Uri.file(path, windows: RegExp(r'^[A-Za-z]:').hasMatch(path));
      }
      await stopped;
      if (!_isCurrent(generation) || _playbackError != null) return;
      await _mutatePlayer(() async {
        if (!_isCurrent(generation)) return;
        final mediaItem = MediaItem(
          id: song.identity,
          album: song.album,
          title: song.title,
          artist: song.artist,
          duration: song.duration > Duration.zero ? song.duration : null,
          artUri: song.albumArtUrl?.isNotEmpty == true
              ? Uri.tryParse(song.albumArtUrl!)
              : null,
        );
        loadingSource = true;
        final duration = await _player.setAudioSource(
          AudioSource.uri(
            uri,
            headers: headers.isEmpty ? null : headers,
            tag: mediaItem,
          ),
        );
        if (!_isCurrent(generation)) return;
        if (duration != null && duration > Duration.zero) {
          _updateDuration(song.identity, duration);
        }
        if (resumeAt > Duration.zero) {
          await _player.seek(resumeAt);
          if (!_isCurrent(generation)) return;
        }
        _readyGeneration = generation;
        _isLoading = false;
        notifyListeners();
        if (_isCurrent(generation) && _wantsToPlay) _startPlaying(generation);
        _preloadNextTrack();
        if ((_continuousDiscovery || _autoQueueRelated) &&
            _remainingQueueCount <= 3 &&
            !_fetchingRelatedSongs &&
            _currentSong != null) {
          unawaited(_fetchAndAppendRelatedSongs(_currentSong!));
        }
      });
    } catch (error) {
      if (song.source == SongSource.youtube && loadingSource) {
        await _handlePlaybackError(generation, error, duringLoad: true);
      } else {
        _failPlayback(generation, error: error);
      }
    }
  }

  void _updateDuration(String identity, Duration duration) {
    final idx = _songIndices[identity];
    if (idx != null) {
      _songs[idx] = _songs[idx].copyWith(duration: duration);
      _catalogRevision++;
    }
    void update(List<Song> songs) {
      for (var i = 0; i < songs.length; i++) {
        if (songs[i].identity == identity) {
          songs[i] = songs[i].copyWith(duration: duration);
        }
      }
    }

    if (_localSongs.any((song) => song.identity == identity)) {
      update(_localSongs);
      _localSongsRevision++;
    }
    update(_queue);
    update(_favorites);
    for (final playlist in _playlists) {
      update(playlist.songs);
    }
    // Use current metadata, not the snapshot from before resolution/favoriting.
    _currentSong = _currentSong!.copyWith(duration: duration);
    _audioHandler?.syncState();
  }

  Future<void> _handlePlaybackError(
    int generation,
    Object error, {
    bool duringLoad = false,
  }) async {
    if (!_isCurrent(generation) ||
        _playbackError != null ||
        (!duringLoad && _readyGeneration != generation)) {
      return;
    }
    if (_currentSong?.videoId != null) {
      _preloadedStreams.remove(_currentSong!.videoId);
    }
    if (!_retryAttempted && _currentSong?.source == SongSource.youtube) {
      _retryAttempted = true;
      // A 403 can mean an expired URL; refresh once, using the stable video ID.
      await _selectSong(
        _currentSong!,
        resumeAt: _playbackPosition,
        retry: true,
        wantsToPlay: _wantsToPlay,
      );
      return;
    }
    _failPlayback(generation, error: error);
  }

  void _failPlayback(int generation, {Object? error}) {
    if (!_isCurrent(generation)) return;
    if (_currentSong?.videoId != null) {
      _preloadedStreams.remove(_currentSong!.videoId);
    }
    _readyGeneration = null;
    _isLoading = false;
    _isPlaying = false;
    _wantsToPlay = false;
    PowerManagerService.instance.releasePlaybackWakeLock();
    final isYoutube = _currentSong?.source == SongSource.youtube;
    _playbackError = isYoutube && kIsWeb
        ? 'YouTube audio is not supported on the web.'
        : classifyPlaybackFailure(error).message(isYoutube: isYoutube);
    notifyListeners();
    // Never print exceptions: player/network errors can include signed URLs.
    unawaited(
      _mutatePlayer(() async {
        if (_isCurrent(generation)) await _player.stop();
      }).catchError((Object _) {}),
    );
  }

  void _startPlaying(int generation) {
    if (!_isCurrent(generation) || !_wantsToPlay) return;
    // just_audio's play future completes only when paused/stopped/completed.
    unawaited(
      Future<void>.sync(_player.play).catchError((Object error) {
        if (_isCurrent(generation) &&
            _currentSong?.source == SongSource.youtube) {
          return _handlePlaybackError(generation, error);
        }
        _failPlayback(generation, error: error);
      }),
    );
  }

  Future<void> _restart(int generation) async {
    try {
      await _mutatePlayer(() async {
        if (!_isCurrent(generation)) return;
        await _player.seek(Duration.zero);
        if (_isCurrent(generation) && _wantsToPlay) _startPlaying(generation);
      });
    } catch (error) {
      _failPlayback(generation, error: error);
    }
  }

  Future<void> retryPlayback() async {
    if (_disposed || _currentSong == null || !_canPlay(_currentSong!)) return;
    if (_currentSong?.videoId != null) {
      _preloadedStreams.remove(_currentSong!.videoId);
    }
    await _selectSong(_currentSong!, resumeAt: _playbackPosition);
  }

  Future<void> play() async {
    if (_disposed || _currentSong == null || !_canPlay(_currentSong!)) return;
    if (_isSimulated(_currentSong!)) {
      if (!_isPlaying) {
        _wantsToPlay = _isPlaying = true;
        notifyListeners();
      }
      return;
    }
    if (_playbackError != null) {
      await retryPlayback();
      return;
    }
    if (_wantsToPlay && _isPlaying) return;
    _wantsToPlay = true;
    _isPlaying = true;
    notifyListeners();
    if (_readyGeneration != _generation) return;
    final generation = _generation;
    try {
      await _mutatePlayer(() async {
        if (!_isCurrent(generation)) return;
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
          if (_isCurrent(generation) && _wantsToPlay) _startPlaying(generation);
        } else {
          _startPlaying(generation);
        }
      });
    } catch (error) {
      _failPlayback(generation, error: error);
    }
  }

  Future<void> pause() async {
    if (_disposed || _currentSong == null) return;
    if (_isSimulated(_currentSong!)) {
      if (_isPlaying) {
        _wantsToPlay = _isPlaying = false;
        notifyListeners();
      }
      return;
    }
    if (!_wantsToPlay && !_isPlaying) return;
    _wantsToPlay = false;
    _isPlaying = false;
    notifyListeners();
    if (_readyGeneration != _generation) return;
    final generation = _generation;
    try {
      await _mutatePlayer(() async {
        if (!_isCurrent(generation)) return;
        await _player.pause();
      });
    } catch (error) {
      _failPlayback(generation, error: error);
    }
  }

  Future<void> togglePlay() async {
    if (_wantsToPlay) {
      await pause();
    } else {
      await play();
    }
  }

  /// Dismiss immediately and invalidate pending loads. Keep the queue for reuse.
  Future<void> stopAndClear() async {
    if (_disposed) return;
    final generation = ++_generation;
    _readyGeneration = null;
    _currentSong = null;
    _currentQueueIndex = -1;
    _manualQueueCount = 0;
    _isLoading = false;
    _playbackError = null;
    _wantsToPlay = false;
    PowerManagerService.instance.releasePlaybackWakeLock();
    _isPlaying = false;
    _preloadingVideoId = null;
    _playbackPosition = Duration.zero;
    playbackPositionNotifier.value = Duration.zero;
    notifyListeners();
    try {
      await _mutatePlayer(() async {
        if (_isCurrent(generation)) await _player.stop();
      });
    } catch (_) {
      // State remains cleared; do not leak platform error details.
    }
  }

  Future<void> seek(Duration position) async {
    if (!canSeek) return;
    final generation = _generation;
    _playbackPosition = position;
    playbackPositionNotifier.value = position;
    if (_isSimulated(_currentSong!)) {
      notifyListeners();
      return;
    }
    try {
      await _mutatePlayer(() async {
        if (_isCurrent(generation) && canSeek) await _player.seek(position);
      });
      _audioHandler?.syncState();
    } catch (error) {
      _failPlayback(generation, error: error);
    }
  }

  Future<void> next() async {
    if (_disposed || _queue.isEmpty) return;
    if (_repeatEnabled && _currentSong != null) {
      await _restart(_generation);
      return;
    }

    // Proactively fetch more related songs if we are at the end of the queue and auto-queue is enabled
    if ((_continuousDiscovery ||
            _autoQueueRelated ||
            _currentSong?.source == SongSource.youtube) &&
        _currentQueueIndex + 1 >= _queue.length) {
      if (_currentSong != null) {
        await _fetchAndAppendRelatedSongs(_currentSong!);
      }
    }

    int nextIndex;
    if (_manualQueueCount > 0) {
      nextIndex = (_currentQueueIndex + 1) % _queue.length;
      _manualQueueCount--;
    } else if (_shuffleEnabled) {
      // Pick only from unplayed songs to guarantee no repetitions
      final unplayedIndices = <int>[];
      for (int i = 0; i < _queue.length; i++) {
        if (i != _currentQueueIndex && !hasSongBeenPlayed(_queue[i])) {
          unplayedIndices.add(i);
        }
      }
      if (unplayedIndices.isNotEmpty) {
        nextIndex = unplayedIndices[Random().nextInt(unplayedIndices.length)];
      } else if (_continuousDiscovery) {
        if (_currentSong != null) {
          await _fetchAndAppendRelatedSongs(_currentSong!);
        }
        nextIndex = _currentQueueIndex + 1 < _queue.length
            ? _currentQueueIndex + 1
            : 0;
      } else {
        nextIndex = (_currentQueueIndex + 1) % _queue.length;
      }
    } else {
      if (_currentQueueIndex + 1 < _queue.length) {
        nextIndex = _currentQueueIndex + 1;
      } else if (_continuousDiscovery) {
        // In continuous explore mode, do not wrap around to repeat played songs
        if (_currentSong != null) {
          await _fetchAndAppendRelatedSongs(_currentSong!);
        }
        if (_currentQueueIndex + 1 < _queue.length) {
          nextIndex = _currentQueueIndex + 1;
        } else {
          return;
        }
      } else {
        nextIndex = (_currentQueueIndex + 1) % _queue.length;
      }
    }

    if (nextIndex < 0 || nextIndex >= _queue.length) return;
    if (!_canPlay(_queue[nextIndex])) return;
    _currentQueueIndex = nextIndex;
    await _selectSong(_queue[nextIndex]);
  }

  Future<void> previous() async {
    if (_disposed || _queue.isEmpty) return;
    if (_playbackPosition.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    final index = _shuffleEnabled
        ? Random().nextInt(_queue.length)
        : (_currentQueueIndex - 1 + _queue.length) % _queue.length;
    if (!_canPlay(_queue[index])) return;
    _currentQueueIndex = index;
    await _selectSong(_queue[index]);
  }

  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    notifyListeners();
    _preloadNextTrack();
  }

  void toggleRepeat() {
    _repeatEnabled = !_repeatEnabled;
    notifyListeners();
  }

  /// Proactively resolves and caches the next track's audio stream in the background
  /// so that when the next track starts or is triggered, there is zero loading latency.
  void _preloadNextTrack() {
    if (_disposed || _queue.isEmpty) return;
    final nextIndex = (_manualQueueCount > 0)
        ? (_currentQueueIndex + 1)
        : (_shuffleEnabled ? -1 : (_currentQueueIndex + 1));

    // Proactively fetch more songs if upcoming queue is running low
    if ((_continuousDiscovery ||
            _autoQueueRelated ||
            _currentSong?.source == SongSource.youtube) &&
        _currentSong != null &&
        !_fetchingRelatedSongs &&
        _remainingQueueCount <= 3) {
      unawaited(_fetchAndAppendRelatedSongs(_currentSong!));
    }

    if (nextIndex < 0 || nextIndex >= _queue.length) {
      return;
    }

    final nextSong = _queue[nextIndex];
    if (nextSong.source != SongSource.youtube || nextSong.videoId == null) {
      return;
    }
    final videoId = nextSong.videoId!;
    final cached = _preloadedStreams[videoId];
    if (cached != null && cached.isValid(_audioQuality)) {
      return;
    }
    if (_preloadingVideoId == videoId) {
      return;
    }

    _preloadingVideoId = videoId;
    final quality = _audioQuality;
    unawaited(
      _resolveYoutubeAudio(videoId, quality: quality).then((stream) {
        if (_disposed) return;
        _preloadedStreams[videoId] = _PreloadedStream(
          stream: stream,
          quality: quality,
          resolvedAt: DateTime.now(),
        );
        // Maintain a bounded cache
        if (_preloadedStreams.length > 10) {
          final oldestKey = _preloadedStreams.keys.first;
          _preloadedStreams.remove(oldestKey);
        }
      }).catchError((_) {
        // Ignored; fallback on-demand resolution will run when track is selected
      }).whenComplete(() {
        if (_preloadingVideoId == videoId) {
          _preloadingVideoId = null;
        }
      }),
    );
  }

  /// Discovers related and random music based on the current track (same movie/soundtrack,
  /// same artist, or explore radio discovery) and appends them to the queue without repeating
  /// previously played tracks.
  Future<void> _fetchAndAppendRelatedSongs(Song song) async {
    if (_disposed || _fetchingRelatedSongs) return;
    _fetchingRelatedSongs = true;
    try {
      List<Song> related = const [];
      if (_continuousDiscovery) {
        final finder = _findRelatedSongs;
        if (finder != null) {
          related = await finder(song, currentQueue: _queue);
        } else {
          related = await RelatedSongsService.instance.findExploreRadioSongs(
            currentSong: song,
            currentQueue: _queue,
            isExcluded: hasSongBeenPlayed,
            limit: 10,
          );
        }
      } else if (song.source == SongSource.youtube) {
        final finder = _findRelatedSongs;
        if (finder != null) {
          related = await finder(song, currentQueue: _queue);
        } else {
          related = await RelatedSongsService.instance.findRelatedSongs(
            song,
            currentQueue: _queue,
            isExcluded: hasSongBeenPlayed,
          );
        }
      } else if (song.source == SongSource.local) {
        related = RelatedSongsService.instance.findRelatedLocalSongs(
          song,
          [..._localSongs, ..._songs],
          currentQueue: _queue,
          isExcluded: hasSongBeenPlayed,
        );
      }

      if (_disposed || related.isEmpty) return;

      final currentIdentities = _queue.map((s) => s.identity).toSet();
      final currentVideoIds =
          _queue.map((s) => s.videoId).whereType<String>().toSet();
      final currentTitles = _queue
          .map((s) => RelatedSongsService.normalizeTitle(s.title))
          .where((t) => t.isNotEmpty)
          .toSet();

      final newTracks = related.where((s) {
        if (hasSongBeenPlayed(s)) return false;
        if (currentIdentities.contains(s.identity)) return false;
        if (s.videoId != null && currentVideoIds.contains(s.videoId!)) {
          return false;
        }
        final t = RelatedSongsService.normalizeTitle(s.title);
        if (t.isNotEmpty && currentTitles.contains(t)) return false;
        return true;
      }).toList();

      if (newTracks.isEmpty) return;

      _registerSongs(newTracks);

      if (_continuousDiscovery ||
          _currentQueueIndex + 1 + _manualQueueCount >= _queue.length) {
        _queue.addAll(newTracks);
      } else {
        final insertPos =
            (_currentQueueIndex >= 0 && _currentQueueIndex < _queue.length)
                ? _currentQueueIndex + 1 + _manualQueueCount
                : _queue.length;
        _queue.insertAll(insertPos, newTracks);
      }
      notifyListeners();

      _preloadNextTrack();
    } catch (e) {
      debugPrint('[AUDIO_SERVICE] Could not load related songs: $e');
    } finally {
      _fetchingRelatedSongs = false;
    }
  }

  void toggleFavorite(Song song) {
    final isFav = isSongFavorite(song);
    if (isFav) {
      _favorites.removeWhere((s) => s.identity == song.identity);
    } else {
      _favorites.add(song.copyWith(isFavorite: true));
    }
    _saveFavorites();
    _syncFavoriteStates();
    notifyListeners();
  }

  // ── Playlist management ───────────────────────────────────────────────────────
  void createPlaylist(String name) {
    _playlists.add(
      Playlist(
        id: _playlists.length,
        name: name,
        songs: [],
        gradientId: _playlists.length,
      ),
    );
    notifyListeners();
  }

  void addSongToPlaylist(Song song, Playlist playlist) {
    if (!playlist.songs.any((s) => s.identity == song.identity)) {
      playlist.songs.add(song);
      notifyListeners();
    }
  }

  void removeSongFromPlaylist(Song song, Playlist playlist) {
    playlist.songs.removeWhere((s) => s.identity == song.identity);
    notifyListeners();
  }

  // ── Local storage scanning ────────────────────────────────────────────────────
  /// Automatically scans local storage for music if permission is already granted.
  /// Does not show a permission prompt to the user.
  Future<void> autoScanIfPermitted() async {
    if (_disposed || _isScanning) return;
    try {
      final bool granted =
          await _platform.invokeMethod<bool>('checkPermission') ?? false;
      if (granted && !_disposed && !_isScanning) {
        await scanLocalSongs(forcePrompt: false);
      }
    } catch (e) {
      debugPrint('[AUDIO_SOURCE] autoScanIfPermitted notice: $e');
    }
  }

  Future<void> scanLocalSongs({bool forcePrompt = false}) {
    if (_disposed) return Future<void>.value();
    return _scanFuture ??= Future<void>.microtask(
      () => _scanLocalSongs(forcePrompt: forcePrompt),
    ).whenComplete(() => _scanFuture = null);
  }

  Future<void> _scanLocalSongs({required bool forcePrompt}) async {
    if (_disposed) return;
    _isScanning = true;
    // Keep the last successful snapshot if the refresh fails.
    notifyListeners();

    try {
      bool granted =
          await _platform.invokeMethod<bool>('checkPermission') ?? false;

      if (_disposed) return;
      if (!granted || forcePrompt) {
        granted =
            await _platform.invokeMethod<bool>('requestPermission') ?? false;
      }
      if (_disposed) return;
      debugPrint('[AUDIO_SOURCE] Storage permission granted=$granted');

      if (granted) {
        final List<dynamic>? songsData = await _platform
            .invokeMethod<List<dynamic>>('fetchLocalSongs');
        if (_disposed) return;
        if (songsData != null) {
          final favIds = _favorites.map((s) => s.identity).toSet();
          _localSongs = songsData.map((data) {
            final map = Map<String, dynamic>.from(data as Map);
            final int id = map['id'] as int;
            final int durationMs = (map['duration'] as int?) ?? 0;
            final String path = (map['path'] as String?) ?? '';
            return Song(
              id: id,
              title: (map['title'] as String?) ?? 'Unknown Title',
              artist: (map['artist'] as String?) ?? 'Unknown Artist',
              album: (map['album'] as String?) ?? 'Local Storage',
              duration: Duration(milliseconds: durationMs),
              audioPath: path,
              gradientId: id.abs(),
              source: SongSource.local,
              isFavorite: favIds.contains('local:$id'),
            );
          }).toList();
          _localSongsRevision++;
          // Drop removed local files without touching other source identities.
          final localIds = _localSongs.map((song) => song.identity).toSet();
          _songs.removeWhere(
            (song) =>
                song.source == SongSource.local &&
                !localIds.contains(song.identity),
          );
          _songIndices.clear();
          for (var i = 0; i < _songs.length; i++) {
            _songIndices[_songs[i].identity] = i;
          }
          _registerSongs(_localSongs);
          await _saveCachedLocalSongs();
          debugPrint(
            '[AUDIO_SOURCE] Scanned ${_localSongs.length} local songs.',
          );
        }
      } else {
        debugPrint('[AUDIO_ERROR] Storage permission was denied by the user.');
      }
    } catch (e, stack) {
      debugPrint('[AUDIO_ERROR] scanLocalSongs failed: $e\n$stack');
    } finally {
      _isScanning = false;
      if (!_disposed) notifyListeners();
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _audioHandler?.detachAudioService(this);
    ++_generation;
    _readyGeneration = null;
    _isLoading = false;
    _isPlaying = false;
    _wantsToPlay = false;
    PowerManagerService.instance.releasePlaybackWakeLock();
    playbackPositionNotifier.dispose();
    _preloadedStreams.clear();
    unawaited(_playerStateSub?.cancel());
    unawaited(_positionSub?.cancel());
    unawaited(_playerCompleteSub?.cancel());
    unawaited(_playbackErrorSub?.cancel());
    unawaited(_mutatePlayer(_player.dispose).catchError((Object _) {}));
    PowerManagerService.instance.releasePlaybackWakeLock();
    super.dispose();
  }
}

class _PreloadedStream {
  final YoutubeAudioStream stream;
  final String quality;
  final DateTime resolvedAt;

  _PreloadedStream({
    required this.stream,
    required this.quality,
    required this.resolvedAt,
  });

  bool isValid(String currentQuality) {
    if (quality != currentQuality) return false;
    return DateTime.now().difference(resolvedAt) < const Duration(hours: 2);
  }
}
