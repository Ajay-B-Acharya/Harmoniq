import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/screens/search_screen.dart';
import 'package:harmoniq/services/audio_service.dart';
import 'package:harmoniq/services/search_suggestion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchSuggestionService', () {
    test('fetches and parses suggestions from YouTube completion endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'suggestqueries.google.com');
        expect(request.url.queryParameters['q'], 'ariana');
        return http.Response(
          jsonEncode([
            'ariana',
            ['ariana grande songs', 'ariana grande positions', 'ariana 7 rings'],
          ]),
          200,
        );
      });

      final service = SearchSuggestionService(client: mockClient);
      final suggestions = await service.fetchOnlineSuggestions('ariana');

      expect(suggestions, [
        'ariana grande songs',
        'ariana grande positions',
        'ariana 7 rings',
      ]);

      // Cache hit test (should not call client again)
      final cached = await service.fetchOnlineSuggestions('ariana');
      expect(cached, suggestions);
    });

    test('combines recent searches, library songs, and online results deduplicated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            'star',
            ['starboy the weeknd', 'star walkin lil nas x'],
          ]),
          200,
        );
      });

      final service = SearchSuggestionService(client: mockClient);
      final librarySong = const Song(
        id: 101,
        title: 'Star Shopping',
        artist: 'Lil Peep',
        album: 'Single',
        duration: Duration(minutes: 2, seconds: 22),
        audioPath: '/music/star_shopping.mp3',
        gradientId: 0,
      );

      final combined = await service.getCombinedSuggestions(
        'star',
        librarySongs: [librarySong],
        recentSearches: ['Starboy'],
      );

      expect(combined.length, 4);
      expect(combined[0].text, 'Starboy');
      expect(combined[0].type, SuggestionType.recent);

      expect(combined[1].text, 'Star Shopping');
      expect(combined[1].type, SuggestionType.library);
      expect(combined[1].song?.artist, 'Lil Peep');

      expect(combined[2].text, 'starboy the weeknd');
      expect(combined[2].type, SuggestionType.online);

      expect(combined[3].text, 'star walkin lil nas x');
      expect(combined[3].type, SuggestionType.online);
    });
  });

  group('SearchScreen Suggestions UI', () {
    late AudioService audioService;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'recent_searches': ['Coldplay Yellow'],
      });
      audioService = AudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    testWidgets('typing query renders suggestion tiles and online search prompt', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            'cold',
            ['coldplay fix you', 'coldplay viva la vida'],
          ]),
          200,
        );
      });

      final suggestionService = SearchSuggestionService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchScreen(
              audioService: audioService,
              onSongTap: (_) {},
              onFavoriteTap: (_) {},
              suggestionService: suggestionService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'Cold');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify prompt via RichText
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Search online for "Cold"'),
        ),
        findsOneWidget,
      );
      expect(find.text('SONG & SEARCH SUGGESTIONS'), findsOneWidget);
      expect(find.text('coldplay fix you'), findsOneWidget);
      expect(find.text('coldplay viva la vida'), findsOneWidget);
    });

    testWidgets('tapping insert icon populates search bar', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            'cold',
            ['coldplay fix you'],
          ]),
          200,
        );
      });

      final suggestionService = SearchSuggestionService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchScreen(
              audioService: audioService,
              onSongTap: (_) {},
              onFavoriteTap: (_) {},
              suggestionService: suggestionService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Cold');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Tap the insert arrow for 'coldplay fix you'
      final insertButtons = find.byTooltip('Insert into search bar');
      expect(insertButtons, findsWidgets);
      await tester.tap(insertButtons.last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'coldplay fix you'), findsOneWidget);
    });
  });
}
