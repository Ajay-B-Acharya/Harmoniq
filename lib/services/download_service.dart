import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import 'audio_service.dart';

enum DownloadQuality {
  low(
    label: 'Low',
    approxBitrateKbps: 96,
    format: 'AAC / M4A',
    description: 'Data saver (~96 kbps)',
    notes: 'Optimized for mobile data savings',
  ),
  normal(
    label: 'Normal',
    approxBitrateKbps: 128,
    format: 'AAC / M4A',
    description: 'Standard (~128 kbps)',
    notes: 'Balanced quality and file size',
  ),
  high(
    label: 'High',
    approxBitrateKbps: 192,
    format: 'AAC / M4A',
    description: 'High quality (~192 kbps)',
    notes: 'Source stream quality (Recommended)',
  ),
  veryHigh(
    label: 'Very High',
    approxBitrateKbps: 320,
    format: 'AAC / M4A',
    description: 'Maximum fidelity (~320 kbps target)',
    notes: 'Captured at highest source bitrate (160–256 kbps)',
  );

  final String label;
  final int approxBitrateKbps;
  final String format;
  final String description;
  final String notes;

  const DownloadQuality({
    required this.label,
    required this.approxBitrateKbps,
    required this.format,
    required this.description,
    required this.notes,
  });

  /// Estimates file size in bytes for a given duration.
  int estimatedBytes(Duration duration) {
    if (duration <= Duration.zero) return 0;
    final seconds = duration.inSeconds;
    return ((approxBitrateKbps * 1000 / 8) * seconds).round();
  }

  /// Formats estimated file size to a human-readable string (e.g. "3.4 MB").
  String formatEstimatedSize(Duration duration) {
    final bytes = estimatedBytes(duration);
    if (bytes <= 0) return 'Approx. ~3–5 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Formats data usage estimate (e.g. "~3.4 MB data").
  String formatDataUsage(Duration duration) {
    final bytes = estimatedBytes(duration);
    if (bytes <= 0) return 'Approx. ~3–5 MB data';
    final mb = bytes / (1024 * 1024);
    return '~${mb.toStringAsFixed(1)} MB data';
  }
}

enum DownloadStatus {
  idle,
  preparing,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadProgress {
  final String songIdentity;
  final Song song;
  final DownloadQuality quality;
  final DownloadStatus status;
  final double? progress; // 0.0 to 1.0, null if indeterminate
  final int receivedBytes;
  final int? totalBytes;
  final String? errorMessage;
  final Song? downloadedSong;

  const DownloadProgress({
    required this.songIdentity,
    required this.song,
    required this.quality,
    required this.status,
    this.progress,
    this.receivedBytes = 0,
    this.totalBytes,
    this.errorMessage,
    this.downloadedSong,
  });

  DownloadProgress copyWith({
    DownloadStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
    Song? downloadedSong,
  }) {
    return DownloadProgress(
      songIdentity: songIdentity,
      song: song,
      quality: quality,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedSong: downloadedSong ?? this.downloadedSong,
    );
  }
}

class DownloadService extends ChangeNotifier {
  static const String preferredQualityKey = 'harmoniq_preferred_download_quality';
  static const MethodChannel _defaultPlatformChannel =
      MethodChannel('com.example.harmoniq/local_music');

  static DownloadService? _instance;
  static DownloadService get instance => _instance ??= DownloadService();

  final AudioService? audioService;
  final http.Client _httpClient;
  final MethodChannel _platformChannel;

  final Map<String, DownloadProgress> _activeDownloads = {};
  final Set<String> _cancellations = {};
  final Map<String, StreamSubscription<List<int>>> _activeSubscriptions = {};
  final Map<String, Completer<void>> _activeCompleters = {};
  final StreamController<DownloadProgress> _progressController =
      StreamController<DownloadProgress>.broadcast();

  DownloadService({
    this.audioService,
    http.Client? httpClient,
    MethodChannel? platformChannel,
  })  : _httpClient = httpClient ?? http.Client(),
        _platformChannel = platformChannel ?? _defaultPlatformChannel;

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  Map<String, DownloadProgress> get activeDownloads =>
      Map.unmodifiable(_activeDownloads);

  bool isDownloading(String songIdentity) {
    final task = _activeDownloads[songIdentity];
    return task != null &&
        (task.status == DownloadStatus.preparing ||
            task.status == DownloadStatus.downloading);
  }

  DownloadProgress? getProgress(String songIdentity) =>
      _activeDownloads[songIdentity];

  /// Loads the saved quality preference. Defaults to [DownloadQuality.high].
  Future<DownloadQuality> getPreferredQuality() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(preferredQualityKey);
      if (name != null) {
        for (final q in DownloadQuality.values) {
          if (q.name == name) return q;
        }
      }
    } catch (_) {}
    return DownloadQuality.high;
  }

  /// Persists preferred quality for future downloads.
  Future<void> setPreferredQuality(DownloadQuality quality) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(preferredQualityKey, quality.name);
    } catch (_) {}
  }

  void _notifyProgress(DownloadProgress progress) {
    _activeDownloads[progress.songIdentity] = progress;
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
    notifyListeners();
  }

  /// Cancels an in-flight download if one exists.
  void cancelDownload(String songIdentity) {
    if (_activeDownloads.containsKey(songIdentity)) {
      _cancellations.add(songIdentity);
      _activeSubscriptions[songIdentity]?.cancel();
      _activeSubscriptions.remove(songIdentity);
      final completer = _activeCompleters.remove(songIdentity);
      if (completer != null && !completer.isCompleted) {
        completer.completeError(StateError('Download cancelled.'));
      }
      final current = _activeDownloads[songIdentity];
      if (current != null) {
        final cancelled = current.copyWith(status: DownloadStatus.cancelled);
        _notifyProgress(cancelled);
      }
    }
  }

  /// Downloads the provided song at the chosen quality.
  ///
  /// Streams the audio chunks to a temporary file, commits to Android
  /// MediaStore under `Music/Harmoniq/` (or platform fallback directory),
  /// and registers the offline song with [AudioService].
  Future<Song> downloadSong(
    Song song,
    DownloadQuality quality, {
    AudioService? overrideAudioService,
  }) async {
    final effectiveAudioService = overrideAudioService ?? audioService;
    if (isDownloading(song.identity)) {
      throw StateError('Download already in progress for "${song.title}".');
    }

    if (song.source == SongSource.local && song.audioPath.isNotEmpty) {
      throw StateError('Song is already stored locally on your device.');
    }

    if (song.source != SongSource.youtube || song.videoId == null) {
      throw StateError('Audio downloads are not available for this song source.');
    }

    if (effectiveAudioService == null) {
      throw StateError('AudioService is required for stream resolution.');
    }

    await setPreferredQuality(quality);
    _cancellations.remove(song.identity);

    var progress = DownloadProgress(
      songIdentity: song.identity,
      song: song,
      quality: quality,
      status: DownloadStatus.preparing,
    );
    _notifyProgress(progress);

    File? tempFile;
    try {
      // 1. Resolve online audio resource
      final youtubeStream =
          await effectiveAudioService.resolveYoutubeStream(song.videoId!);
      final uri = youtubeStream.uri;
      final headers = Map<String, String>.from(youtubeStream.headers);

      if (_cancellations.contains(song.identity)) {
        throw StateError('Download cancelled.');
      }

      // 2. Open HTTP GET stream
      final request = http.Request('GET', uri);
      request.headers.addAll(headers);

      final response = await _httpClient.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'HTTP ${response.statusCode}: Stream download failed',
          uri: uri,
        );
      }

      final contentLength = response.contentLength;
      var receivedBytes = 0;

      progress = progress.copyWith(
        status: DownloadStatus.downloading,
        totalBytes: contentLength,
        progress: (contentLength != null && contentLength > 0) ? 0.0 : null,
      );
      _notifyProgress(progress);

      // 3. Stream chunks to scratch temp file
      final tempDir = Directory.systemTemp;
      final tempFileName =
          'harmoniq_dl_${song.videoId}_${DateTime.now().millisecondsSinceEpoch}.part';
      tempFile = File('${tempDir.path}/$tempFileName');
      final sink = tempFile.openWrite();

      var lastNotifyTime = DateTime.now();

      final streamCompleter = Completer<void>();
      late StreamSubscription<List<int>> streamSub;

      streamSub = response.stream.listen(
        (chunk) {
          if (_cancellations.contains(song.identity)) {
            streamSub.cancel();
            if (!streamCompleter.isCompleted) {
              streamCompleter.completeError(StateError('Download cancelled.'));
            }
            return;
          }

          try {
            sink.add(chunk);
            receivedBytes += chunk.length;

            final now = DateTime.now();
            if (now.difference(lastNotifyTime).inMilliseconds >= 100 ||
                (contentLength != null && receivedBytes == contentLength)) {
              lastNotifyTime = now;
              final fraction = (contentLength != null && contentLength > 0)
                  ? (receivedBytes / contentLength).clamp(0.0, 1.0)
                  : null;
              progress = progress.copyWith(
                receivedBytes: receivedBytes,
                progress: fraction,
              );
              _notifyProgress(progress);
            }
          } catch (e) {
            streamSub.cancel();
            if (!streamCompleter.isCompleted) {
              streamCompleter.completeError(e);
            }
          }
        },
        onError: (Object error) {
          if (!streamCompleter.isCompleted) {
            streamCompleter.completeError(error);
          }
        },
        onDone: () {
          if (!streamCompleter.isCompleted) {
            streamCompleter.complete();
          }
        },
        cancelOnError: true,
      );

      _activeSubscriptions[song.identity] = streamSub;
      _activeCompleters[song.identity] = streamCompleter;

      try {
        await streamCompleter.future;
      } finally {
        _activeSubscriptions.remove(song.identity);
        _activeCompleters.remove(song.identity);
        await sink.flush();
        await sink.close();
      }

      // 4. Validate downloaded file integrity
      final fileLength = await tempFile.length();
      if (fileLength == 0) {
        await tempFile.delete();
        throw StateError('Downloaded audio resource was empty.');
      }

      // 5. Commit to MediaStore / storage
      final savedAudioPath = await _saveAudioToStorage(
        song: song,
        quality: quality,
        tempFile: tempFile,
      );

      // 6. Create offline local Song model
      final downloadedSong = Song(
        id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
        title: song.title,
        artist: song.artist,
        album: song.album.isNotEmpty && song.album != 'YouTube'
            ? song.album
            : 'Harmoniq Downloads',
        duration: song.duration,
        audioPath: savedAudioPath,
        isFavorite: song.isFavorite,
        gradientId: song.gradientId,
        albumArtUrl: song.albumArtUrl,
        source: SongSource.local,
        videoId: song.videoId,
        audioDownloadAllowed: true,
        downloadQuality: quality.label,
      );

      // 7. Register in Harmoniq Library
      await effectiveAudioService.addDownloadedSong(downloadedSong);

      progress = progress.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        receivedBytes: fileLength,
        downloadedSong: downloadedSong,
      );
      _notifyProgress(progress);

      return downloadedSong;
    } catch (e) {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      final isCancelled = _cancellations.contains(song.identity) ||
          e.toString().contains('cancelled');
      final finalStatus =
          isCancelled ? DownloadStatus.cancelled : DownloadStatus.failed;
      final errorMessage =
          isCancelled ? 'Download cancelled' : _formatErrorMessage(e);

      progress = progress.copyWith(
        status: finalStatus,
        errorMessage: errorMessage,
      );
      _notifyProgress(progress);

      rethrow;
    } finally {
      _cancellations.remove(song.identity);
    }
  }

  Future<String> _saveAudioToStorage({
    required Song song,
    required DownloadQuality quality,
    required File tempFile,
  }) async {
    final cleanTitle = _sanitizeFileName(song.title);
    final cleanArtist = _sanitizeFileName(song.artist);
    final fileName = '${cleanArtist}_${cleanTitle}_${quality.name}';

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final resultUri = await _platformChannel.invokeMethod<String>(
          'saveDownloadedAudio',
          {
            'title': song.title,
            'artist': song.artist,
            'album': song.album.isNotEmpty && song.album != 'YouTube'
                ? song.album
                : 'Harmoniq',
            'durationMs': song.duration.inMilliseconds,
            'mimeType': 'audio/mp4',
            'displayName': '$fileName.m4a',
            'tempFilePath': tempFile.path,
          },
        );
        if (resultUri != null && resultUri.isNotEmpty) {
          return resultUri;
        }
      } catch (e) {
        debugPrint('[DOWNLOAD_SERVICE] MediaStore invocation notice: $e');
      }
    }

    // Fallback: copy directly into Music/Harmoniq directory
    final fallbackDir = await _getFallbackHarmoniqDirectory();
    final targetFile = File('${fallbackDir.path}/$fileName.m4a');
    await tempFile.copy(targetFile.path);
    try {
      await tempFile.delete();
    } catch (_) {}
    return targetFile.path;
  }

  Future<Directory> _getFallbackHarmoniqDirectory() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir = Directory('/storage/emulated/0/Music');
    } else {
      final userHome = Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          Directory.systemTemp.path;
      baseDir = Directory('$userHome/Music');
    }

    if (!baseDir.existsSync()) {
      baseDir = Directory.systemTemp;
    }

    final target = Directory('${baseDir.path}/Harmoniq');
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }
    return target;
  }

  String _sanitizeFileName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'song' : sanitized;
  }

  String _formatErrorMessage(Object error) {
    if (error is SocketException) {
      return 'Network connection failed. Please check your internet connection.';
    }
    if (error is HttpException) {
      return 'Server error during download: ${error.message}';
    }
    if (error is FormatException) {
      return 'Audio stream formatting error.';
    }
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  @override
  void dispose() {
    for (final sub in _activeSubscriptions.values) {
      sub.cancel();
    }
    _activeSubscriptions.clear();
    for (final completer in _activeCompleters.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Download service disposed.'));
      }
    }
    _activeCompleters.clear();
    _progressController.close();
    super.dispose();
  }
}
