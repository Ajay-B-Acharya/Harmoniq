import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/services/audio_service.dart' as app;
import 'package:harmoniq/services/harmoniq_audio_handler.dart';
import 'package:just_audio/just_audio.dart';

// Mock audio player for unit testing HarmoniqAudioHandler integration
class _MockAudioPlayer implements AudioPlayer {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();

  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HarmoniqAudioHandler handler;
  late app.AudioService audioService;

  setUp(() {
    handler = HarmoniqAudioHandler();
    audioService = app.AudioService(
      audioPlayer: _MockAudioPlayer(),
      audioHandler: handler,
    );
  });

  tearDown(() {
    audioService.dispose();
  });

  test('handler registers and synchronizes with AudioService', () {
    expect(HarmoniqAudioHandler.instance, isNotNull);
  });

  test('notification controls include previous and next buttons when song is loaded', () async {
    const song1 = Song(
      id: 1,
      title: 'First Track',
      artist: 'Artist One',
      album: 'Album One',
      duration: Duration(minutes: 3),
      audioPath: 'simulated_1',
      source: SongSource.local,
      gradientId: 0,
    );
    const song2 = Song(
      id: 2,
      title: 'Second Track',
      artist: 'Artist Two',
      album: 'Album Two',
      duration: Duration(minutes: 4),
      audioPath: 'simulated_2',
      source: SongSource.local,
      gradientId: 1,
    );

    audioService.registerSongs([song1, song2]);
    await audioService.playSong(song1, contextQueue: [song1, song2]);

    final state = handler.playbackState.value;
    expect(state, isNotNull);

    // Verify controls contain skipToPrevious, pause/play, skipToNext
    final controlActions = state.controls.map((c) => c.action).toList();
    expect(controlActions, contains(MediaAction.skipToPrevious));
    expect(controlActions, contains(MediaAction.skipToNext));
    expect(
      controlActions,
      anyOf(contains(MediaAction.play), contains(MediaAction.pause)),
    );

    // Compact indices must include previous (0), play/pause (1), and next (2)
    expect(state.androidCompactActionIndices, [0, 1, 2]);

    // System actions must support next and previous for Bluetooth & OS media session
    expect(state.systemActions, contains(MediaAction.skipToNext));
    expect(state.systemActions, contains(MediaAction.skipToPrevious));

    // MediaItem should reflect active track
    final item = handler.mediaItem.value;
    expect(item, isNotNull);
    expect(item!.id, song1.identity);
    expect(item.title, 'First Track');
    expect(item.artist, 'Artist One');
  });

  test('notification skipToNext advances queue to the next song', () async {
    const song1 = Song(
      id: 1,
      title: 'First Track',
      artist: 'Artist One',
      album: 'Album One',
      duration: Duration(minutes: 3),
      audioPath: 'simulated_1',
      source: SongSource.local,
      gradientId: 0,
    );
    const song2 = Song(
      id: 2,
      title: 'Second Track',
      artist: 'Artist Two',
      album: 'Album Two',
      duration: Duration(minutes: 4),
      audioPath: 'simulated_2',
      source: SongSource.local,
      gradientId: 1,
    );

    audioService.registerSongs([song1, song2]);
    await audioService.playSong(song1, contextQueue: [song1, song2]);
    expect(audioService.currentSong?.identity, song1.identity);

    // Simulate clicking next on notification
    await handler.skipToNext();
    expect(audioService.currentSong?.identity, song2.identity);

    final item = handler.mediaItem.value;
    expect(item?.id, song2.identity);
    expect(item?.title, 'Second Track');
  });

  test('notification skipToPrevious changes track or restarts position', () async {
    const song1 = Song(
      id: 1,
      title: 'First Track',
      artist: 'Artist One',
      album: 'Album One',
      duration: Duration(minutes: 3),
      audioPath: 'simulated_1',
      source: SongSource.local,
      gradientId: 0,
    );
    const song2 = Song(
      id: 2,
      title: 'Second Track',
      artist: 'Artist Two',
      album: 'Album Two',
      duration: Duration(minutes: 4),
      audioPath: 'simulated_2',
      source: SongSource.local,
      gradientId: 1,
    );

    audioService.registerSongs([song1, song2]);
    await audioService.playSong(song2, contextQueue: [song1, song2]);
    expect(audioService.currentSong?.identity, song2.identity);

    // Clicking previous when under 3 seconds goes to preceding song
    await handler.skipToPrevious();
    expect(audioService.currentSong?.identity, song1.identity);

    final item = handler.mediaItem.value;
    expect(item?.id, song1.identity);
  });

  test('notification play and pause update handler playbackState', () async {
    const song1 = Song(
      id: 1,
      title: 'Track',
      artist: 'Artist',
      album: 'Album',
      duration: Duration(minutes: 3),
      audioPath: 'simulated_1',
      source: SongSource.local,
      gradientId: 0,
    );

    audioService.registerSongs([song1]);
    await audioService.playSong(song1, contextQueue: [song1]);

    await handler.pause();
    expect(audioService.isPlaying, isFalse);

    await handler.play();
    expect(audioService.isPlaying, isTrue);
  });

  test('notification stop clears playback state and mediaItem', () async {
    const song1 = Song(
      id: 1,
      title: 'Track',
      artist: 'Artist',
      album: 'Album',
      duration: Duration(minutes: 3),
      audioPath: 'simulated_1',
      source: SongSource.local,
      gradientId: 0,
    );

    audioService.registerSongs([song1]);
    await audioService.playSong(song1, contextQueue: [song1]);
    expect(handler.mediaItem.value, isNotNull);

    await handler.stop();
    expect(handler.mediaItem.value, isNull);
    expect(handler.playbackState.value.playing, isFalse);
  });
}
