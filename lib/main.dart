import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/now_playing_screen.dart';
import 'widgets/auth_gate.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/mini_player.dart';
import 'widgets/motion.dart';
import 'widgets/spatial_background.dart';
import 'models/song.dart';
import 'models/youtube_video.dart';
import 'widgets/opening_animation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase Initialization (Safe / Non-blocking failure)
  try {
    await initSupabase();
  } catch (e) {
    debugPrint('[STARTUP] Supabase initialization notice: $e');
  }

  // 2. Background Audio Initialization (Safe fallback)
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.harmoniq.channel.audio',
      androidNotificationChannelName: 'Harmoniq Audio Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    );
  } catch (e) {
    debugPrint('[STARTUP] JustAudioBackground initialization notice: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harmoniq',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: SplashScreen(authService: _authService),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final AuthService authService;
  const SplashScreen({super.key, required this.authService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissionsOnce();
  }

  void _proceedToMain() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a1, a2) => AuthGate(authService: widget.authService),
        transitionsBuilder: (ctx, animation, a2, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: motionDuration(context, 200),
      ),
    );
  }

  Future<void> _checkAndRequestPermissionsOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyAsked =
          prefs.getBool('has_prompted_app_permissions') ?? false;
      if (!alreadyAsked) {
        const platform = MethodChannel('com.example.harmoniq/local_music');
        await platform.invokeMethod('requestAllPermissions');
        await prefs.setBool('has_prompted_app_permissions', true);
      }
    } catch (e) {
      debugPrint('[PERMISSIONS] Initial check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OpeningAnimationView(
      onFinished: _proceedToMain,
    );
  }
}

class MainContainer extends StatefulWidget {
  final AudioService? audioService;
  final AuthService? authService;
  const MainContainer({super.key, this.audioService, this.authService});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final AudioService _audioService;
  late final AuthService _authService;

  late final List<Widget> _pages;
  final _searchKey = GlobalKey<SearchScreenState>();
  final _libraryKey = GlobalKey<LibraryScreenState>();

  @override
  void initState() {
    super.initState();
    _audioService = widget.audioService ?? AudioService();
    _authService = widget.authService ?? AuthService();
    _pageController = PageController();

    _pages = [
      HomeScreen(
        onLocalTap: _openLocalMusic,
        onSearchTap: _openSearch,
        onVideoTap: _playYoutube,
        onVideoQueueTap: _playYoutubeQueue,
        onProfileTap: () => _onTabTap(4),
        audioService: _audioService,
        authService: _authService,
        onSongTap: (song, [queue]) =>
            _playSong(song, contextQueue: queue ?? _audioService.songs),
        onPlaylistPlayTap: (playlist) {
          if (playlist.songs.isNotEmpty) {
            _playSong(playlist.songs[0], contextQueue: playlist.songs);
          }
        },
      ),
      ExploreScreen(
        audioService: _audioService,
        onSongTap: (song, [queue]) =>
            _playSong(song, contextQueue: queue ?? _audioService.songs),
        onFavoriteTap: _audioService.toggleFavorite,
        onSearchTap: _openSearch,
        onProfileTap: () => _onTabTap(4),
      ),
      LibraryScreen(
        key: _libraryKey,
        audioService: _audioService,
        onSongTap: (song) => _playSong(song, contextQueue: _audioService.songs),
        onFavoriteTap: _audioService.toggleFavorite,
        onCreatePlaylist: _audioService.createPlaylist,
      ),
      SearchScreen(
        key: _searchKey,
        onVideoTap: _playYoutube,
        onVideoQueueTap: _playYoutubeQueue,
        onProfileTap: () => _onTabTap(4),
        audioService: _audioService,
        onSongTap: (song) => _playSong(song, contextQueue: _audioService.songs),
        onFavoriteTap: _audioService.toggleFavorite,
      ),
      ProfileScreen(
        audioService: _audioService,
        authService: _authService,
        onLocalTap: _openLocalMusic,
        onSearchTap: _openSearch,
      ),
    ];
  }

  void _openLocalMusic() {
    _onTabTap(2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _libraryKey.currentState?.selectCategory(5);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (widget.audioService == null) _audioService.dispose();
    if (widget.authService == null) _authService.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    if (MediaQuery.disableAnimationsOf(context) ||
        (index - _currentIndex).abs() > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _playSong(Song song, {List<Song>? contextQueue}) async {
    if (song.source == SongSource.legacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This saved track is from the previous source.'),
          action: SnackBarAction(
            label: 'Search Track',
            onPressed: () => _openSearch('${song.title} ${song.artist}'),
          ),
        ),
      );
      return;
    }
    await _audioService.playSong(song, contextQueue: contextQueue);
  }

  void _openSearch(String query) {
    _onTabTap(3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchKey.currentState?.setQuery(query);
    });
  }

  void _playYoutube(YoutubeVideo video) => _playYoutubeQueue(video, [video]);

  void _playYoutubeQueue(YoutubeVideo video, List<YoutubeVideo> videos) {
    final song = Song.fromYoutube(video);
    unawaited(
      _audioService.playSong(
        song,
        contextQueue: videos.map(Song.fromYoutube).toList(),
      ),
    );
    _openNowPlaying();
  }

  void _openNowPlaying() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, a1, a2) => NowPlayingScreen(
          audioService: _audioService,
          onClose: () => Navigator.pop(context),
        ),
        transitionsBuilder: (ctx, animation, a2, child) {
          final tween = Tween(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: motionDuration(context, 340),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpatialBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: List.generate(
                _pages.length,
                (index) => _RetainedPage(
                  child: TickerMode(
                    enabled: index == _currentIndex,
                    child: _pages[index],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListenableBuilder(
                listenable: _audioService,
                builder: (context, child) {
                  final song = _audioService.currentSong;
                  final player = song == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 10),
                          child: MiniPlayer(
                            song: song,
                            isPlaying: _audioService.isPlaying,
                            isLoading: _audioService.isLoading,
                            playbackError: _audioService.playbackError,
                            wantsToPlay: _audioService.wantsToPlay,
                            onRetryTap: _audioService.retryPlayback,
                            positionNotifier:
                                _audioService.playbackPositionNotifier,
                            onTap: _openNowPlaying,
                            onPlayPauseTap: _audioService.togglePlay,
                            onNextTap: _audioService.next,
                            onPreviousTap: _audioService.previous,
                            onCloseTap: _audioService.stopAndClear,
                          ),
                        );
                  if (MediaQuery.disableAnimationsOf(context)) return player;
                  return AnimatedSize(
                    duration: motionDuration(context),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.bottomCenter,
                    child: player,
                  );
                },
              ),
              BottomNav(currentIndex: _currentIndex, onTap: _onTabTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetainedPage extends StatefulWidget {
  final Widget child;
  const _RetainedPage({required this.child});

  @override
  State<_RetainedPage> createState() => _RetainedPageState();
}

class _RetainedPageState extends State<_RetainedPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
