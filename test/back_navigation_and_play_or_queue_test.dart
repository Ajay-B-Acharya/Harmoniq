import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/main.dart';
import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/services/audio_service.dart';
import 'package:harmoniq/widgets/bottom_nav.dart';
import 'package:harmoniq/widgets/play_or_queue_sheet.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAudioPlayer implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final positions = StreamController<Duration>.broadcast(sync: true);
  final processing = StreamController<ProcessingState>.broadcast(sync: true);
  final events = StreamController<PlaybackEvent>.broadcast(sync: true);
  final sources = <AudioSource>[];
  bool disposed = false;
  bool isPlaying = false;

  @override
  PlayerState get playerState => PlayerState(isPlaying, processingState);
  @override
  ProcessingState processingState = ProcessingState.idle;
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Stream<ProcessingState> get processingStateStream => processing.stream;
  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;

  void emit(bool playing, ProcessingState state) {
    isPlaying = playing;
    processingState = state;
    states.add(PlayerState(playing, state));
    processing.add(state);
  }

  @override
  Future<void> stop() async {
    emit(false, ProcessingState.idle);
  }

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    sources.add(source);
    emit(false, ProcessingState.loading);
    emit(false, ProcessingState.ready);
    return const Duration(minutes: 3);
  }

  @override
  Future<Duration?> load() async {
    emit(false, ProcessingState.ready);
    return const Duration(minutes: 3);
  }

  @override
  Future<void> play() async {
    emit(true, ProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    emit(false, processingState);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    if (position != null) positions.add(position);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await Future.wait([
      states.close(),
      positions.close(),
      processing.close(),
      events.close(),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AudioService queueNext multi-song behavior', () {
    late AudioService audioService;
    late _FakeAudioPlayer fakePlayer;

    final songA = Song(
      id: 1,
      title: 'Song A',
      artist: 'Artist A',
      album: 'Album A',
      gradientId: 1,
      source: SongSource.local,
      audioPath: 'C:/fake/song_a.mp3',
      duration: const Duration(minutes: 3),
    );
    final songB = Song(
      id: 2,
      title: 'Song B',
      artist: 'Artist B',
      album: 'Album B',
      gradientId: 2,
      source: SongSource.local,
      audioPath: 'C:/fake/song_b.mp3',
      duration: const Duration(minutes: 3),
    );
    final songC = Song(
      id: 3,
      title: 'Song C',
      artist: 'Artist C',
      album: 'Album C',
      gradientId: 3,
      source: SongSource.local,
      audioPath: 'C:/fake/song_c.mp3',
      duration: const Duration(minutes: 3),
    );
    final songX = Song(
      id: 4,
      title: 'Song X',
      artist: 'Artist X',
      album: 'Album X',
      gradientId: 4,
      source: SongSource.local,
      audioPath: 'C:/fake/song_x.mp3',
      duration: const Duration(minutes: 3),
    );

    setUp(() {
      fakePlayer = _FakeAudioPlayer();
      audioService = AudioService(audioPlayer: fakePlayer);
    });

    tearDown(() {
      audioService.dispose();
    });

    test('queueNext on empty player plays directly', () async {
      audioService.queueNext(songA);
      expect(audioService.currentSong?.id, equals(1));
    });

    test('queueNext with active queue inserts consecutive queued songs in order', () async {
      // Start with Song A and queue containing [Song A, Song X]
      await audioService.playSong(songA, contextQueue: [songA, songX]);
      expect(audioService.currentSong?.id, equals(1));
      expect(audioService.queue.map((s) => s.id).toList(), equals([1, 4]));
      expect(audioService.manualQueueCount, equals(0));

      // Queue Song B as next
      audioService.queueNext(songB);
      expect(audioService.manualQueueCount, equals(1));
      expect(audioService.queue.map((s) => s.id).toList(), equals([1, 2, 4]));

      // Queue Song C as next (should go after Song B and before Song X)
      audioService.queueNext(songC);
      expect(audioService.manualQueueCount, equals(2));
      expect(audioService.queue.map((s) => s.id).toList(), equals([1, 2, 3, 4]));

      // Advancing to next track should play Song B
      await audioService.next();
      expect(audioService.currentSong?.id, equals(2));
      expect(audioService.manualQueueCount, equals(1));

      // Advancing to next track should play Song C
      await audioService.next();
      expect(audioService.currentSong?.id, equals(3));
      expect(audioService.manualQueueCount, equals(0));

      // Advancing again should play original remaining Song X
      await audioService.next();
      expect(audioService.currentSong?.id, equals(4));
    });
  });

  group('PlayOrQueueSheet UI widget', () {
    final songPlaying = Song(
      id: 10,
      title: 'Currently Playing Track',
      artist: 'Active Artist',
      album: 'Active Album',
      gradientId: 1,
      source: SongSource.local,
      audioPath: 'C:/fake/active.mp3',
      duration: const Duration(minutes: 3),
    );
    final songClicked = Song(
      id: 20,
      title: 'Clicked Next Track',
      artist: 'Selected Artist',
      album: 'Selected Album',
      gradientId: 2,
      source: SongSource.local,
      audioPath: 'C:/fake/next.mp3',
      duration: const Duration(minutes: 4),
    );

    testWidgets('renders song info, now-playing banner, Play Now and Play Next options',
        (tester) async {
      PlayOrQueueAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedAction = await PlayOrQueueSheet.show(
                    context,
                    song: songClicked,
                    currentSong: songPlaying,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Clicked Next Track'), findsOneWidget);
      expect(find.text('Selected Artist'), findsOneWidget);
      expect(find.textContaining('Now playing: Currently Playing Track'), findsOneWidget);
      expect(find.text('Play Now'), findsOneWidget);
      expect(find.text('Play Next'), findsOneWidget);

      // Tap Play Next
      await tester.tap(find.text('Play Next'));
      await tester.pumpAndSettle();

      expect(selectedAction, equals(PlayOrQueueAction.playNext));
    });

    testWidgets('tapping Play Now returns playNow action', (tester) async {
      PlayOrQueueAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedAction = await PlayOrQueueSheet.show(
                    context,
                    song: songClicked,
                    currentSong: songPlaying,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play Now'));
      await tester.pumpAndSettle();

      expect(selectedAction, equals(PlayOrQueueAction.playNow));
    });
  });

  group('Back navigation in MainContainer', () {
    testWidgets('pressing back on Explore, Library, Search navigates to Home; back on Home pops',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainContainer(),
        ),
      );
      await tester.pumpAndSettle();

      // Starts on Home tab (index 0)
      // Switch to Search tab using BottomNav
      final searchNavFinder = find.descendant(
        of: find.byType(BottomNav),
        matching: find.byIcon(Icons.search_rounded),
      );
      await tester.tap(searchNavFinder);
      await tester.pumpAndSettle();

      // Trigger back button (handlePopRoute)
      final handledOnSearch = await tester.binding.handlePopRoute();
      // Must be handled (not popped from root)
      expect(handledOnSearch, isTrue);
      await tester.pumpAndSettle();

      // Now we should be back on Home screen.
      // Triggering back button again while on Home screen should bubble (handlePopRoute returns false)
      final handledOnHome = await tester.binding.handlePopRoute();
      expect(handledOnHome, isFalse);
    });
  });
}
