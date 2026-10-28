import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'audio_service.dart' as app;

/// Global entry point to initialize the native background audio service
/// and media notification handlers.
Future<HarmoniqAudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => HarmoniqAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.harmoniq.channel.audio',
      androidNotificationChannelName: 'Harmoniq Audio Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/launcher_icon',
    ),
  );
}

/// Custom [AudioHandler] connecting Harmoniq's audio player with Android's
/// MediaSessionCompat / MediaStyle notifications and lockscreen controls.
class HarmoniqAudioHandler extends BaseAudioHandler with SeekHandler {
  static HarmoniqAudioHandler? instance;

  app.AudioService? _audioService;

  HarmoniqAudioHandler() {
    instance = this;
  }

  void attachAudioService(app.AudioService service) {
    if (_audioService == service) return;
    _audioService?.removeListener(_syncState);
    _audioService = service;
    service.addListener(_syncState);
    _syncState();
  }

  void detachAudioService([app.AudioService? service]) {
    if (service != null && _audioService != service) return;
    _audioService?.removeListener(_syncState);
    _audioService = null;
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(
        processingState: AudioProcessingState.idle,
        playing: false,
        controls: const [],
        systemActions: const {},
      ),
    );
  }

  void syncState() {
    _syncState();
  }

  void _syncState() {
    final svc = _audioService;
    if (svc == null) return;

    final song = svc.currentSong;
    if (song == null) {
      if (mediaItem.value != null) {
        mediaItem.add(null);
      }
      playbackState.add(
        PlaybackState(
          processingState: AudioProcessingState.idle,
          playing: false,
          controls: const [],
          systemActions: const {},
        ),
      );
      return;
    }

    final duration = song.duration > Duration.zero ? song.duration : null;
    final currentItem = mediaItem.value;
    final needsItemUpdate = currentItem == null ||
        currentItem.id != song.identity ||
        currentItem.title != song.title ||
        currentItem.artist != song.artist ||
        currentItem.album != song.album ||
        currentItem.duration != duration;

    if (needsItemUpdate) {
      mediaItem.add(
        MediaItem(
          id: song.identity,
          album: song.album.isNotEmpty ? song.album : 'Unknown Album',
          title: song.title.isNotEmpty ? song.title : 'Unknown Track',
          artist: song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
          duration: duration,
          artUri: song.albumArtUrl?.isNotEmpty == true
              ? Uri.tryParse(song.albumArtUrl!)
              : null,
        ),
      );
    }

    final isPlaying = svc.isPlaying;
    final isLoading = svc.isLoading;
    final hasError = svc.playbackError != null;

    final AudioProcessingState processingState;
    if (hasError) {
      processingState = AudioProcessingState.error;
    } else if (isLoading) {
      processingState = AudioProcessingState.loading;
    } else if (isPlaying) {
      processingState = AudioProcessingState.ready;
    } else {
      processingState = AudioProcessingState.ready;
    }

    // Media notification controls including Previous and Next buttons:
    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];

    final systemActions = <MediaAction>{
      MediaAction.seek,
      MediaAction.seekForward,
      MediaAction.seekBackward,
      MediaAction.skipToNext,
      MediaAction.skipToPrevious,
    };

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: systemActions,
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: isPlaying && !isLoading && !hasError,
        updatePosition: svc.playbackPosition,
        bufferedPosition: svc.playbackPosition,
        speed: isPlaying ? 1.0 : 0.0,
        queueIndex: svc.currentQueueIndex >= 0 ? svc.currentQueueIndex : null,
      ),
    );

    // Keep queue updated for Android Auto / notification queue interfaces
    final svcQueue = svc.queue;
    if (svcQueue.isNotEmpty) {
      final queueItems = svcQueue
          .map(
            (s) => MediaItem(
              id: s.identity,
              album: s.album.isNotEmpty ? s.album : 'Unknown Album',
              title: s.title.isNotEmpty ? s.title : 'Unknown Track',
              artist: s.artist.isNotEmpty ? s.artist : 'Unknown Artist',
              duration: s.duration > Duration.zero ? s.duration : null,
              artUri: s.albumArtUrl?.isNotEmpty == true
                  ? Uri.tryParse(s.albumArtUrl!)
                  : null,
            ),
          )
          .toList();
      queue.add(queueItems);
    }
  }

  @override
  Future<void> play() async {
    await _audioService?.play();
  }

  @override
  Future<void> pause() async {
    await _audioService?.pause();
  }

  @override
  Future<void> stop() async {
    await _audioService?.stopAndClear();
  }

  @override
  Future<void> skipToNext() async {
    await _audioService?.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _audioService?.previous();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioService?.seek(position);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _audioService?.skipToIndex(index);
  }
}
