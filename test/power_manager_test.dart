import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/screens/profile_screen.dart';
import 'package:harmoniq/services/audio_service.dart';
import 'package:harmoniq/services/auth_service.dart';
import 'package:harmoniq/services/power_manager_service.dart';
import 'package:harmoniq/theme/app_theme.dart';
import 'package:harmoniq/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthService extends AuthService {
  _MockAuthService() : super(client: null);
  @override
  bool get isAuthenticated => false;
}

class _MockAudioService extends AudioService {
  @override
  Song? get currentSong => null;
  @override
  List<Song> get queue => const [];
  @override
  int get currentQueueIndex => -1;
  @override
  bool get isPlaying => false;
  @override
  bool get isLoading => false;
  @override
  List<Song> get songs => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.instance.init();
  });

  group('PowerManagerService', () {
    test('isIgnoringBatteryOptimizations invokes platform channel', () async {
      const channel = MethodChannel('com.example.harmoniq/local_music');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'isIgnoringBatteryOptimizations') {
          return true;
        }
        return null;
      });

      final result =
          await PowerManagerService.instance.isIgnoringBatteryOptimizations();
      expect(result, isTrue);
    });

    testWidgets(
        'ProfileScreen displays Background Playback setting tile and shows dialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final audioService = _MockAudioService();
      final authService = _MockAuthService();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProfileScreen(
            audioService: audioService,
            authService: authService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tileFinder = find.text('Background Playback');
      await tester.scrollUntilVisible(
        tileFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tileFinder, findsOneWidget);

      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      expect(find.text('Background Power Usage'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
