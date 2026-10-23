import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/models/youtube_video.dart';
import 'package:harmoniq/screens/explore_screen.dart';
import 'package:harmoniq/services/audio_service.dart';
import 'package:harmoniq/theme/app_colors.dart';
import 'package:harmoniq/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioService audioService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    audioService = AudioService();
  });

  tearDown(() {
    audioService.dispose();
  });

  double contrastRatio(Color fg, Color bg) {
    final l1 = fg.computeLuminance();
    final l2 = bg.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  group('ExploreScreen Text Visibility & Contrast Tests', () {
    testWidgets('Light mode: Popular Genres have dark text with high contrast', (tester) async {
      tester.view.physicalSize = const Size(1200 * 2.0, 1600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExploreScreen(
            audioService: audioService,
            onSongTap: (_, [_]) {},
            onFavoriteTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all visible genre labels
      final genreNames = ['Pop', 'Hip-Hop', 'Rock', 'Electronic', 'Bollywood'];
      for (final name in genreNames) {
        final textFinder = find.text(name);
        expect(textFinder, findsOneWidget, reason: 'Genre "$name" should be present');

        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.style?.color, isNot(Colors.white),
            reason: 'Genre "$name" should NOT have white text in light mode');

        // Contrast against light background must be high (> 4.5:1 WCAG AA)
        final effectiveColor = textWidget.style?.color ?? Colors.black;
        const lightBg = Color(0xFFFBF6EC);
        final ratio = contrastRatio(effectiveColor, lightBg);
        expect(ratio, greaterThan(4.5),
            reason: 'Genre "$name" must have contrast ratio > 4.5:1 against light background');
      }

      // Check section titles
      expect(find.text('Discover New Vibes'), findsWidgets);
      expect(find.text('Live mixes, top releases & curated sounds'), findsOneWidget);
      expect(find.text('Popular Genres'), findsOneWidget);
      expect(find.text('Trending Playlists'), findsOneWidget);
      expect(find.text('Global Hits'), findsOneWidget);
      expect(find.text('Viral Tracks'), findsOneWidget);

      expect(find.text('Moods & Activities'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Relax'), findsOneWidget);
      expect(find.text('Road Trip'), findsOneWidget);

      expect(find.text('Discovered Tracks'), findsOneWidget);

      // Verify headings are not white in light mode
      final headingWidget = tester.widget<Text>(find.text('Popular Genres'));
      expect(headingWidget.style?.color, isNot(Colors.white));
    });

    testWidgets('Dark mode: Popular Genres have light text with high contrast', (tester) async {
      tester.view.physicalSize = const Size(1200 * 2.0, 1600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ExploreScreen(
            audioService: audioService,
            onSongTap: (_, [_]) {},
            onFavoriteTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all genre labels in dark mode
      final genreNames = ['Pop', 'Hip-Hop', 'Rock', 'Electronic', 'Bollywood'];
      for (final name in genreNames) {
        final textFinder = find.text(name);
        expect(textFinder, findsOneWidget, reason: 'Genre "$name" should be present');

        final textWidget = tester.widget<Text>(textFinder);
        final effectiveColor = textWidget.style?.color ?? Colors.white;

        // In dark mode, card background is deep dark (luminance < 0.05)
        const darkBg = Color(0xFF141F2B);
        final ratio = contrastRatio(effectiveColor, darkBg);
        expect(ratio, greaterThan(4.5),
            reason: 'Genre "$name" must have contrast ratio > 4.5:1 against dark background in dark mode');
      }

      // Check section titles in dark mode
      final headingWidget = tester.widget<Text>(find.text('Popular Genres'));
      expect(headingWidget.style?.color, AppDarkColors.textPrimary);
    });

    testWidgets('Discovered Tracks list displays songs and can scroll to bottom', (tester) async {
      tester.view.physicalSize = const Size(420 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockVideos = List.generate(
        8,
        (i) => YoutubeVideo(
          id: 'vid_$i',
          title: 'Discovered Track #$i',
          artist: 'Artist $i',
          duration: const Duration(seconds: 210),
          thumbnailUrl: '',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExploreScreen(
            audioService: audioService,
            loadVideos: () async => mockVideos,
            onSongTap: (_, [_]) {},
            onFavoriteTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollableFinder = find.byType(Scrollable).first;

      // Scroll to Discovered Tracks
      await tester.scrollUntilVisible(
        find.text('Discovered Track #0'),
        300,
        scrollable: scrollableFinder,
      );
      expect(find.text('Discovered Track #0'), findsOneWidget);

      // Scroll down to the last item
      await tester.scrollUntilVisible(
        find.text('Discovered Track #7'),
        300,
        scrollable: scrollableFinder,
      );
      expect(find.text('Discovered Track #7'), findsOneWidget);
    });
  });
}
