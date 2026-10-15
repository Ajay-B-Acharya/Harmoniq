import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/models/playlist.dart';
import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/screens/explore_screen.dart';
import 'package:harmoniq/screens/history_screen.dart';
import 'package:harmoniq/screens/home_screen.dart';
import 'package:harmoniq/screens/library_screen.dart';
import 'package:harmoniq/screens/main_card_screen.dart';
import 'package:harmoniq/screens/now_playing_screen.dart';
import 'package:harmoniq/screens/profile_screen.dart';
import 'package:harmoniq/screens/search_screen.dart';
import 'package:harmoniq/services/audio_service.dart';
import 'package:harmoniq/services/auth_service.dart';
import 'package:harmoniq/theme/app_theme.dart';
import 'package:harmoniq/widgets/bottom_nav.dart';
import 'package:harmoniq/widgets/mini_player.dart';
import 'package:harmoniq/widgets/spatial_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAudioService extends AudioService {
  final List<Song> _mockSongs = [
    Song(
      id: 1,
      title: 'Midnight Echoes',
      artist: 'Lunar Pulse',
      album: 'Astral Frequencies',
      duration: const Duration(minutes: 3, seconds: 45),
      audioPath: '',
      gradientId: 0,
    ),
    Song(
      id: 2,
      title: 'Starlight Drift',
      artist: 'Cyber Bloom',
      album: 'Deep Atmosphere',
      duration: const Duration(minutes: 4, seconds: 12),
      audioPath: '',
      gradientId: 1,
    ),
    Song(
      id: 3,
      title: 'Neon Horizon',
      artist: 'Vapor Wave',
      album: 'Spatial Horizons',
      duration: const Duration(minutes: 2, seconds: 58),
      audioPath: '',
      gradientId: 2,
    ),
    Song(
      id: 4,
      title: 'Quantum Chill',
      artist: 'Cosmic Shift',
      album: 'Good Vibes',
      duration: const Duration(minutes: 3, seconds: 20),
      audioPath: '',
      gradientId: 3,
    ),
  ];

  @override
  Song? get currentSong => _mockSongs[0];

  @override
  List<Song> get queue => _mockSongs;

  @override
  int get currentQueueIndex => 0;

  @override
  bool get isPlaying => false;

  @override
  bool get isLoading => false;

  @override
  bool get wantsToPlay => true;

  @override
  bool get canSeek => true;

  @override
  List<Song> get songs => _mockSongs;

  @override
  List<Song> get localSongs => [_mockSongs[1]];

  @override
  List<Song> get favorites => [_mockSongs[0], _mockSongs[2]];

  @override
  List<Song> get recentlyPlayed => _mockSongs;

  @override
  List<Playlist> get playlists => [
        Playlist(
          id: 1,
          name: 'Night Drive',
          songs: _mockSongs,
          gradientId: 0,
        ),
        Playlist(
          id: 2,
          name: 'Deep Focus',
          songs: [_mockSongs[1], _mockSongs[3]],
          gradientId: 4,
        ),
      ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'pref_audio_quality': 'High',
      'pref_offline_mode': false,
    });
  });

  Future<void> captureScreen({
    required WidgetTester tester,
    required Widget content,
    required int navIndex,
    required String filename,
    bool showMiniPlayer = true,
  }) async {
    final service = _MockAudioService();
    final repaintKey = GlobalKey();

    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(420 * 2.0, 840 * 2.0); // 420x840 logical
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: RepaintBoundary(
            key: repaintKey,
            child: SpatialBackground(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  content,
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showMiniPlayer)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 6),
                            child: MiniPlayer(
                              song: service.currentSong!,
                              isPlaying: false,
                              positionNotifier: ValueNotifier(const Duration(seconds: 75)),
                              onTap: () {},
                              onPlayPauseTap: () async {},
                              onNextTap: () async {},
                            ),
                          ),
                        BottomNav(
                          currentIndex: navIndex,
                          onTap: (_) {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byKey(repaintKey),
      matchesGoldenFile('goldens/$filename'),
    );
  }

  testWidgets('Capture Home Screen screenshot', (tester) async {
    final service = _MockAudioService();
    final authService = AuthService();

    await captureScreen(
      tester: tester,
      content: HomeScreen(
        audioService: service,
        authService: authService,
        onSongTap: (song, [queue]) {},
        onPlaylistPlayTap: (playlist) {},
        youtubeConfigured: false,
      ),
      navIndex: 0,
      filename: 'screenshot_01_home.png',
    );
  });

  testWidgets('Capture Explore Screen screenshot', (tester) async {
    final service = _MockAudioService();

    await captureScreen(
      tester: tester,
      content: ExploreScreen(
        audioService: service,
        onSongTap: (song, [queue]) {},
        onFavoriteTap: (song) {},
      ),
      navIndex: 1,
      filename: 'screenshot_02_explore.png',
    );
  });

  testWidgets('Capture Library Screen screenshot', (tester) async {
    final service = _MockAudioService();

    await captureScreen(
      tester: tester,
      content: LibraryScreen(
        audioService: service,
        onSongTap: (_) {},
        onFavoriteTap: (_) {},
        onCreatePlaylist: (_) {},
      ),
      navIndex: 2,
      filename: 'screenshot_03_library.png',
    );
  });

  testWidgets('Capture Search Screen screenshot', (tester) async {
    final service = _MockAudioService();

    await captureScreen(
      tester: tester,
      content: SearchScreen(
        audioService: service,
        onSongTap: (_) {},
        onFavoriteTap: (_) {},
        youtubeConfigured: false,
      ),
      navIndex: 3,
      filename: 'screenshot_04_search.png',
    );
  });

  testWidgets('Capture Profile Screen screenshot', (tester) async {
    final service = _MockAudioService();
    final authService = AuthService();

    await captureScreen(
      tester: tester,
      content: ProfileScreen(
        audioService: service,
        authService: authService,
      ),
      navIndex: 4,
      filename: 'screenshot_05_profile.png',
    );
  });

  testWidgets('Capture Now Playing Screen screenshot', (tester) async {
    final service = _MockAudioService();
    final repaintKey = GlobalKey();

    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(420 * 2.0, 840 * 2.0);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: repaintKey,
          child: NowPlayingScreen(
            audioService: service,
            onClose: () {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byKey(repaintKey),
      matchesGoldenFile('goldens/screenshot_06_now_playing.png'),
    );
  });

  testWidgets('Capture Main Card Screen screenshot', (tester) async {
    final repaintKey = GlobalKey();
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(420 * 2.0, 840 * 2.0);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: repaintKey,
          child: const MainCardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byKey(repaintKey),
      matchesGoldenFile('goldens/screenshot_07_main_card.png'),
    );
  });

  testWidgets('Capture History Screen screenshot', (tester) async {
    final repaintKey = GlobalKey();
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(420 * 2.0, 840 * 2.0);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: repaintKey,
          child: const HistoryScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byKey(repaintKey),
      matchesGoldenFile('goldens/screenshot_08_history.png'),
    );
  });
}
