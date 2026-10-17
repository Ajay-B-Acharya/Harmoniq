import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/services/audio_service.dart';
import 'package:harmoniq/services/related_songs_service.dart';
import 'package:harmoniq/services/yt_dlp_channel.dart';
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

Song makeYoutubeSong(String id, String title, String artist, {String? album}) =>
    Song(
      id: 0,
      title: title,
      artist: artist,
      album: album ?? 'YouTube',
      duration: const Duration(minutes: 3),
      audioPath: '',
      gradientId: 1,
      source: SongSource.youtube,
      videoId: id,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RelatedSongsService Metadata Parsing', () {
    test('cleanTitle strips noise words, video descriptors, and pipe segments', () {
      expect(
        RelatedSongsService.cleanTitle(
          'Kesariya - Brahmāstra | Ranbir Kapoor | Alia Bhatt | Pritam | Arijit Singh [Official Video]',
        ),
        'Kesariya',
      );

      expect(
        RelatedSongsService.cleanTitle(
          'Tum Hi Ho (From "Aashiqui 2") (Official Music Video)',
        ),
        'Tum Hi Ho',
      );

      expect(
        RelatedSongsService.cleanTitle('Shape of You [Official 4K UHD Video]'),
        'Shape of You',
      );

      expect(
        RelatedSongsService.cleanTitle('Blinding Lights (Official Audio)'),
        'Blinding Lights',
      );
    });

    test('cleanArtist strips Topic, VEVO, and Official tags', () {
      expect(
        RelatedSongsService.cleanArtist('Arijit Singh - Topic'),
        'Arijit Singh',
      );
      expect(
        RelatedSongsService.cleanArtist('TheWeekndVEVO'),
        'TheWeeknd',
      );
      expect(
        RelatedSongsService.cleanArtist('Sony Music India'),
        'Sony Music India',
      );
    });

    test('extractMovieOrAlbum correctly identifies soundtrack source', () {
      final songWithFrom = makeYoutubeSong(
        'vid12345678',
        'Tum Hi Ho (From "Aashiqui 2")',
        'Arijit Singh',
      );
      expect(RelatedSongsService.extractMovieOrAlbum(songWithFrom), 'Aashiqui 2');

      final songWithDash = makeYoutubeSong(
        'vid87654321',
        'Kesariya - Brahmāstra | Ranbir Kapoor',
        'Pritam',
      );
      expect(RelatedSongsService.extractMovieOrAlbum(songWithDash), 'Brahmāstra');

      final songWithExplicitAlbum = makeYoutubeSong(
        'vid11223344',
        'Deva Deva',
        'Arijit Singh',
        album: 'Brahmāstra Soundtrack',
      );
      expect(
        RelatedSongsService.extractMovieOrAlbum(songWithExplicitAlbum),
        'Brahmāstra Soundtrack',
      );
    });

    test('findRelatedLocalSongs matches same album, artist, and remaining library', () {
      final current = const Song(
        id: 1,
        title: 'Song 1',
        artist: 'Artist A',
        album: 'Album 1',
        duration: Duration(minutes: 3),
        audioPath: '/music/1.mp3',
        gradientId: 1,
      );
      final sameAlbum = const Song(
        id: 2,
        title: 'Song 2',
        artist: 'Artist B',
        album: 'Album 1',
        duration: Duration(minutes: 3),
        audioPath: '/music/2.mp3',
        gradientId: 2,
      );
      final sameArtist = const Song(
        id: 3,
        title: 'Song 3',
        artist: 'Artist A',
        album: 'Album 2',
        duration: Duration(minutes: 3),
        audioPath: '/music/3.mp3',
        gradientId: 3,
      );
      final other = const Song(
        id: 4,
        title: 'Song 4',
        artist: 'Artist C',
        album: 'Album 3',
        duration: Duration(minutes: 3),
        audioPath: '/music/4.mp3',
        gradientId: 4,
      );

      final related = RelatedSongsService.instance.findRelatedLocalSongs(
        current,
        [current, sameAlbum, sameArtist, other],
      );

      // Current song is excluded
      expect(related.any((s) => s.id == 1), isFalse);
      // Same album and same artist come first
      expect(related.first.id, 2);
      expect(related[1].id, 3);
      expect(related.contains(other), isTrue);
    });
  });

  group('AudioService Preloading and Related Autoplay', () {
    test('autoQueueRelated populates queue with related songs and preloads next track', () async {
      final player = _FakeAudioPlayer();
      final songA = makeYoutubeSong('vidAAAAAAAA', 'Kesariya', 'Arijit Singh');
      final songB = makeYoutubeSong('vidBBBBBBBB', 'Deva Deva', 'Arijit Singh');
      final songC = makeYoutubeSong('vidCCCCCCCC', 'Rasiya', 'Pritam');

      final resolvedIds = <String>[];
      final completerMap = <String, Completer<YoutubeAudioStream>>{};

      Future<YoutubeAudioStream> resolve(String id, {String? quality}) {
        resolvedIds.add(id);
        final c = Completer<YoutubeAudioStream>();
        completerMap[id] = c;
        c.complete(YoutubeAudioStream(Uri.parse('https://audio.example/$id')));
        return c.future;
      }

      final service = AudioService(
        resolveYoutubeStream: resolve,
        audioPlayer: player,
        findRelatedSongs: (song, {currentQueue, limit = 12}) async {
          return [songB, songC];
        },
      );

      // Play songA with autoQueueRelated enabled (e.g. from Search)
      await service.playSong(songA, autoQueueRelated: true);

      expect(service.currentSong?.videoId, 'vidAAAAAAAA');
      expect(resolvedIds, contains('vidAAAAAAAA'));

      // Allow background related song discovery and preload to execute
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Queue should now contain songA and the discovered related songs
      expect(service.queue.map((s) => s.videoId).toList(), [
        'vidAAAAAAAA',
        'vidBBBBBBBB',
        'vidCCCCCCCC',
      ]);

      // Next track (songB) should have been preloaded in advance!
      expect(resolvedIds, contains('vidBBBBBBBB'));

      // Transition to next song
      await service.next();

      // Current song is now songB
      expect(service.currentSong?.videoId, 'vidBBBBBBBB');
      // SongB was already preloaded, so no extra resolution call was needed for songB!
      expect(
        resolvedIds.where((id) => id == 'vidBBBBBBBB').length,
        1,
        reason: 'Preloaded stream must be used without re-resolving',
      );

      // Now songC should be preloaded as the subsequent next track
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(resolvedIds, contains('vidCCCCCCCC'));

      service.dispose();
    });

    test('seamless continuous autoplay at the end of the queue fetches more related songs', () async {
      final player = _FakeAudioPlayer();
      final songA = makeYoutubeSong('vid11111111', 'Tum Hi Ho', 'Arijit Singh');
      final songB = makeYoutubeSong('vid22222222', 'Sunn Raha Hai', 'Ankit Tiwari');

      Future<YoutubeAudioStream> resolve(String id, {String? quality}) async {
        return YoutubeAudioStream(Uri.parse('https://audio.example/$id'));
      }

      var relatedCallCount = 0;
      final service = AudioService(
        resolveYoutubeStream: resolve,
        audioPlayer: player,
        findRelatedSongs: (song, {currentQueue, limit = 12}) async {
          relatedCallCount++;
          return [songB];
        },
      );

      // Play single song with empty queue and autoQueueRelated enabled
      await service.playSong(songA, contextQueue: [songA], autoQueueRelated: true);
      expect(service.queue.length, 1);

      // Trigger next() when at the end of queue
      await service.next();

      // AudioService proactively fetches related song and continues playback seamlessly
      expect(relatedCallCount, greaterThanOrEqualTo(1));
      expect(service.currentSong?.videoId, 'vid22222222');

      service.dispose();
    });
  });
}
