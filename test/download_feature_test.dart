import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/screens/library_screen.dart';
import 'package:harmoniq/screens/now_playing_screen.dart';
import 'package:harmoniq/services/audio_service.dart';
import 'package:harmoniq/services/download_service.dart';
import 'package:harmoniq/services/yt_dlp_channel.dart';
import 'package:harmoniq/widgets/download_progress_bar.dart';
import 'package:harmoniq/widgets/download_quality_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MockStreamHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) _handler;

  MockStreamHttpClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

class _TestAudioService extends AudioService {
  Song? testSong;
  List<Song> testQueue = [];

  _TestAudioService({required this.testSong}) {
    if (testSong != null) testQueue = [testSong!];
  }

  @override
  Song? get currentSong => testSong;

  @override
  List<Song> get queue => testQueue;

  @override
  int get currentQueueIndex => testSong != null ? 0 : -1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DownloadQuality Model', () {
    test('quality options have correct bitrates and non-empty metadata', () {
      expect(DownloadQuality.low.approxBitrateKbps, 96);
      expect(DownloadQuality.normal.approxBitrateKbps, 128);
      expect(DownloadQuality.high.approxBitrateKbps, 192);
      expect(DownloadQuality.veryHigh.approxBitrateKbps, 320);

      for (final q in DownloadQuality.values) {
        expect(q.label.isNotEmpty, isTrue);
        expect(q.format, contains('MP3'));
        expect(q.description.isNotEmpty, isTrue);
        expect(q.notes.isNotEmpty, isTrue);
      }
    });

    test('calculates accurate estimated sizes for durations', () {
      const duration = Duration(minutes: 3, seconds: 20); // 200 seconds
      // 96 kbps -> 96,000 / 8 * 200 = 2,400,000 bytes (~2.28 MB)
      final lowBytes = DownloadQuality.low.estimatedBytes(duration);
      expect(lowBytes, 2400000);
      expect(DownloadQuality.low.formatEstimatedSize(duration), '2.3 MB');
      expect(DownloadQuality.low.formatDataUsage(duration), '~2.3 MB data');

      // 192 kbps -> 192,000 / 8 * 200 = 4,800,000 bytes (~4.57 MB)
      final highBytes = DownloadQuality.high.estimatedBytes(duration);
      expect(highBytes, 4800000);
      expect(DownloadQuality.high.formatEstimatedSize(duration), '4.6 MB');
      expect(DownloadQuality.high.formatDataUsage(duration), '~4.6 MB data');

      // Zero duration handling
      expect(DownloadQuality.high.estimatedBytes(Duration.zero), 0);
      expect(DownloadQuality.high.formatEstimatedSize(Duration.zero),
          'Approx. ~3–5 MB');
    });
  });

  group('AudioService Download Management', () {
    test('add, check, retrieve, and remove downloaded song', () async {
      final audioService = AudioService(
        resolveYoutubeStream: (id) async =>
            YoutubeAudioStream(Uri.parse('https://example.com/audio.m4a')),
      );

      const onlineSong = Song(
        id: 0,
        title: 'Cyberpunk Beats',
        artist: 'Neon Wave',
        album: 'Synth',
        duration: Duration(minutes: 3),
        audioPath: '',
        gradientId: 1,
        source: SongSource.youtube,
        videoId: 'dQw4w9WgXcQ',
      );

      expect(audioService.isSongDownloaded(onlineSong), isFalse);
      expect(audioService.getDownloadedSong(onlineSong), isNull);

      final downloadedSong = Song(
        id: 9999,
        title: onlineSong.title,
        artist: onlineSong.artist,
        album: 'Harmoniq Downloads',
        duration: onlineSong.duration,
        audioPath: '/data/storage/Music/Harmoniq/song.m4a',
        gradientId: onlineSong.gradientId,
        source: SongSource.local,
        videoId: onlineSong.videoId,
        downloadQuality: 'High',
      );

      final initialRevision = audioService.downloadsRevision;
      await audioService.addDownloadedSong(downloadedSong);

      expect(audioService.downloadedSongs.length, 1);
      expect(audioService.isSongDownloaded(onlineSong), isTrue);
      expect(audioService.getDownloadedSong(onlineSong), isNotNull);
      expect(audioService.getDownloadedSong(onlineSong)?.audioPath,
          downloadedSong.audioPath);
      expect(audioService.downloadsRevision, greaterThan(initialRevision));

      // Remove downloaded song
      await audioService.removeDownloadedSong(downloadedSong);
      expect(audioService.downloadedSongs.isEmpty, isTrue);
      expect(audioService.isSongDownloaded(onlineSong), isFalse);

      audioService.dispose();
    });

    test('persists downloaded songs in SharedPreferences across reload', () async {
      SharedPreferences.setMockInitialValues({});
      final audioService1 = AudioService(
        resolveYoutubeStream: (id) async =>
            YoutubeAudioStream(Uri.parse('https://example.com/audio.m4a')),
      );

      const song = Song(
        id: 1234,
        title: 'Offline Track',
        artist: 'Harmoniq Artist',
        album: 'Harmoniq Downloads',
        duration: Duration(seconds: 180),
        audioPath: '/local/path/song.m4a',
        gradientId: 2,
        source: SongSource.local,
        videoId: 'video123456',
        downloadQuality: 'Normal',
      );

      await audioService1.addDownloadedSong(song);
      audioService1.dispose();

      // Second instance loads persisted downloads
      final audioService2 = AudioService(
        resolveYoutubeStream: (id) async =>
            YoutubeAudioStream(Uri.parse('https://example.com/audio.m4a')),
      );
      // Wait for async prefs loading
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(audioService2.downloadedSongs.length, 1);
      expect(audioService2.downloadedSongs.first.title, 'Offline Track');
      expect(audioService2.downloadedSongs.first.downloadQuality, 'Normal');
      expect(audioService2.downloadedSongs.first.source, SongSource.local);

      audioService2.dispose();
    });
  });

  group('DownloadService Streaming & Storage', () {
    test('successfully downloads chunked stream and registers song', () async {
      final audioService = AudioService(
        resolveYoutubeStream: (id) async =>
            YoutubeAudioStream(Uri.parse('https://example.com/stream.m4a')),
      );

      final fakeAudioBytes = List.generate(4096, (i) => i % 256);
      final client = MockStreamHttpClient((request) async {
        return http.StreamedResponse(
          Stream.fromIterable([
            fakeAudioBytes.sublist(0, 2048),
            fakeAudioBytes.sublist(2048),
          ]),
          200,
          contentLength: 4096,
        );
      });

      final downloadService = DownloadService(
        audioService: audioService,
        httpClient: client,
      );

      const song = Song(
        id: 0,
        title: 'Cosmic Drift',
        artist: 'Starlight',
        album: 'Space',
        duration: Duration(minutes: 3),
        audioPath: '',
        gradientId: 3,
        source: SongSource.youtube,
        videoId: '12345678901',
      );

      expect(downloadService.isDownloading(song.identity), isFalse);

      final progressEvents = <DownloadProgress>[];
      final sub = downloadService.progressStream.listen(progressEvents.add);

      final downloadedSong =
          await downloadService.downloadSong(song, DownloadQuality.high);

      expect(downloadedSong.title, 'Cosmic Drift');
      expect(downloadedSong.source, SongSource.local);
      expect(downloadedSong.audioPath.isNotEmpty, isTrue);
      expect(downloadedSong.downloadQuality, 'High');

      // Verify song was registered in audioService
      expect(audioService.isSongDownloaded(song), isTrue);

      await sub.cancel();
      downloadService.dispose();
      audioService.dispose();
    });

    test('handles HTTP failure gracefully', () async {
      final audioService = AudioService(
        resolveYoutubeStream: (id) async =>
            YoutubeAudioStream(Uri.parse('https://example.com/stream.m4a')),
      );

      final client = MockStreamHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value([]),
          404,
        );
      });

      final downloadService = DownloadService(
        audioService: audioService,
        httpClient: client,
      );

      const song = Song(
        id: 0,
        title: 'Unavailable Track',
        artist: 'Ghost',
        album: 'Unknown',
        duration: Duration(minutes: 2),
        audioPath: '',
        gradientId: 0,
        source: SongSource.youtube,
        videoId: 'missingvid1',
      );

      await expectLater(
        downloadService.downloadSong(song, DownloadQuality.normal),
        throwsA(isA<HttpException>()),
      );

      downloadService.dispose();
      audioService.dispose();
    });

    test('cancelling download stops stream and cleans up', () async {
      final audioService = AudioService(
        resolveYoutubeStream: (id) async =>
            YoutubeAudioStream(Uri.parse('https://example.com/stream.m4a')),
      );

      final controller = StreamController<List<int>>();
      final client = MockStreamHttpClient((request) async {
        return http.StreamedResponse(
          controller.stream,
          200,
          contentLength: 100000,
        );
      });

      final downloadService = DownloadService(
        audioService: audioService,
        httpClient: client,
      );

      const song = Song(
        id: 0,
        title: 'Long Download',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(minutes: 5),
        audioPath: '',
        gradientId: 0,
        source: SongSource.youtube,
        videoId: 'longdownload',
      );

      final downloadFuture =
          downloadService.downloadSong(song, DownloadQuality.high);

      // Allow event loop to start the HTTP request and establish stream
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Add a chunk
      controller.add([1, 2, 3, 4, 5]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Cancel
      downloadService.cancelDownload(song.identity);

      await expectLater(
        downloadFuture,
        throwsA(isA<StateError>()),
      );

      if (!controller.isClosed) await controller.close();
      downloadService.dispose();
      audioService.dispose();
    });

    test('successfully downloads and bundles sample/simulated song offline', () async {
      final audioService = AudioService(
        resolveYoutubeStream: (id) async =>
            YoutubeAudioStream(Uri.parse('https://example.com/stream.m4a')),
      );

      final downloadService = DownloadService(
        audioService: audioService,
      );

      const sampleSong = Song(
        id: 0,
        title: 'Midnight Drive',
        artist: 'Rayan',
        album: 'Retro Dreams',
        duration: Duration(minutes: 3, seconds: 42),
        audioPath: 'simulated_midnight_drive.mp3',
        gradientId: 0,
        source: SongSource.local,
      );

      expect(audioService.isSongDownloaded(sampleSong), isFalse);

      final downloadedSong = await downloadService.downloadSong(
        sampleSong,
        DownloadQuality.normal,
      );

      expect(downloadedSong.title, 'Midnight Drive');
      expect(downloadedSong.artist, 'Rayan');
      expect(downloadedSong.source, SongSource.local);
      expect(downloadedSong.audioPath.isNotEmpty, isTrue);
      expect(File(downloadedSong.audioPath).existsSync(), isTrue);
      expect(downloadedSong.downloadQuality, 'Normal');

      // Verify audioService identifies it as downloaded
      expect(audioService.isSongDownloaded(sampleSong), isTrue);
      expect(audioService.getDownloadedSong(sampleSong), isNotNull);
      expect(audioService.downloadedSongs.length, 1);

      // Clean up downloaded file
      await audioService.removeDownloadedSong(downloadedSong);
      expect(audioService.isSongDownloaded(sampleSong), isFalse);

      downloadService.dispose();
      audioService.dispose();
    });
  });

  group('Download Quality Sheet Widget', () {
    testWidgets('renders song info and all 4 quality options', (tester) async {
      const song = Song(
        id: 0,
        title: 'Solar Flare',
        artist: 'Aurora',
        album: 'Cosmic',
        duration: Duration(minutes: 3, seconds: 30),
        audioPath: '',
        gradientId: 4,
        source: SongSource.youtube,
        videoId: 'aurora12345',
      );

      DownloadQuality? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selected = await DownloadQualitySheet.show(
                    context,
                    song: song,
                    initialQuality: DownloadQuality.high,
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

      // Check title, subtitle, song info
      expect(find.text('Download Song'), findsOneWidget);
      expect(find.text('Choose audio quality for offline listening.'),
          findsOneWidget);
      expect(find.text('Solar Flare'), findsOneWidget);
      expect(find.text('Aurora'), findsOneWidget);

      // Check quality options
      expect(find.text('LOW'), findsOneWidget);
      expect(find.text('NORMAL'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('VERY HIGH'), findsOneWidget);
      expect(find.text('RECOMMENDED'), findsOneWidget);

      // Select 'LOW'
      await tester.tap(find.text('LOW'));
      await tester.pumpAndSettle();

      // Confirm download
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(selected, DownloadQuality.low);
    });

    testWidgets('cancel button dismisses sheet with null', (tester) async {
      const song = Song(
        id: 0,
        title: 'Solar Flare',
        artist: 'Aurora',
        album: 'Cosmic',
        duration: Duration(minutes: 3),
        audioPath: '',
        gradientId: 4,
        source: SongSource.youtube,
        videoId: 'aurora12345',
      );

      DownloadQuality? selected = DownloadQuality.high;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selected = await DownloadQualitySheet.show(
                    context,
                    song: song,
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

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });

  group('NowPlayingScreen Download Menu', () {
    testWidgets('shows Download option in song options menu', (tester) async {
      const song = Song(
        id: 0,
        title: 'Current Hit',
        artist: 'Top Artist',
        album: 'Album',
        duration: Duration(minutes: 3),
        audioPath: '',
        gradientId: 5,
        source: SongSource.youtube,
        videoId: 'currenthit1',
      );

      final audioService = _TestAudioService(testSong: song);

      await tester.pumpWidget(
        MaterialApp(
          home: NowPlayingScreen(
            audioService: audioService,
            onClose: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Tap three dots (Song options)
      final optionsButton = find.byTooltip('Song options');
      expect(optionsButton, findsOneWidget);
      await tester.tap(optionsButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Download option is present alongside favorites and playlist
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Add to favorites'), findsOneWidget);
      expect(find.text('Add to playlist'), findsOneWidget);

      audioService.dispose();
    });
  });

  group('LibraryScreen Downloads Tab', () {
    testWidgets('shows Downloads category and displays downloaded songs',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final audioService = AudioService(
        resolveYoutubeStream: (id) async =>
            YoutubeAudioStream(Uri.parse('https://example.com/audio.m4a')),
      );

      const downloadedSong = Song(
        id: 555,
        title: 'Downloaded Hit',
        artist: 'Offline Artist',
        album: 'Harmoniq Downloads',
        duration: Duration(minutes: 3, seconds: 15),
        audioPath: '/data/user/0/music/hit.m4a',
        gradientId: 6,
        source: SongSource.local,
        videoId: 'offlinevid1',
        downloadQuality: 'High',
      );

      await audioService.addDownloadedSong(downloadedSong);

      Song? tappedSong;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryScreen(
              audioService: audioService,
              onSongTap: (s) => tappedSong = s,
              onFavoriteTap: (_) {},
              onCreatePlaylist: (_) {},
              initialCategoryIndex: 6, // Downloads tab
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Downloads tab category chip
      expect(find.text('Downloads'), findsOneWidget);

      // Verify downloaded song is displayed
      expect(find.text('Downloaded Hit'), findsOneWidget);
      expect(find.textContaining('Available offline'), findsOneWidget);

      // Tap on the downloaded song
      await tester.tap(find.text('Downloaded Hit'));
      await tester.pumpAndSettle();

      expect(tappedSong?.title, 'Downloaded Hit');

      audioService.dispose();
    });

    testWidgets('shows empty state when no songs are downloaded',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final audioService = AudioService(
        resolveYoutubeStream: (id) async =>
            YoutubeAudioStream(Uri.parse('https://example.com/audio.m4a')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryScreen(
              audioService: audioService,
              onSongTap: (_) {},
              onFavoriteTap: (_) {},
              onCreatePlaylist: (_) {},
              initialCategoryIndex: 6, // Downloads tab
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No downloaded songs yet'), findsOneWidget);
      expect(
        find.text(
            'Download songs from the Now Playing menu for offline listening.'),
        findsOneWidget,
      );

      audioService.dispose();
    });
  });

  group('DownloadProgressBar Widget', () {
    testWidgets('renders download progress, bytes, and cancel button',
        (tester) async {
      const song = Song(
        id: 1,
        title: 'Cyberpunk Odyssey',
        artist: 'Neon Wave',
        album: 'Harmoniq',
        duration: Duration(minutes: 3),
        audioPath: '',
        gradientId: 1,
        source: SongSource.youtube,
        videoId: 'cyber123',
      );

      final audioService = AudioService(
        resolveYoutubeStream: (id) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return YoutubeAudioStream(Uri.parse('https://example.com/audio.m4a'));
        },
      );

      final downloadService = DownloadService(audioService: audioService);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DownloadProgressBar(downloadService: downloadService),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially empty
      expect(find.text('Cyberpunk Odyssey'), findsNothing);

      // Trigger download
      unawaited(downloadService.downloadSong(song, DownloadQuality.high));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Bar is visible with song title and cancel icon
      expect(find.text('Cyberpunk Odyssey'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap cancel
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      audioService.dispose();
      downloadService.dispose();
    });
  });
}

