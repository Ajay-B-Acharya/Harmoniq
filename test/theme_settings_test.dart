import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/screens/home_screen.dart';
import 'package:harmoniq/screens/profile_screen.dart';
import 'package:harmoniq/services/audio_service.dart';
import 'package:harmoniq/services/auth_service.dart';
import 'package:harmoniq/theme/app_colors.dart';
import 'package:harmoniq/theme/app_theme.dart';
import 'package:harmoniq/theme/theme_controller.dart';
import 'package:harmoniq/widgets/neumorphic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(client: null);
  @override
  bool get isAuthenticated => false;
}

class _FakeAudioService extends AudioService {
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.instance.init();
    await ThemeController.instance.setThemeMode(ThemeMode.light);
  });

  group('ThemeController', () {
    test('defaults to Light theme and updates correctly', () async {
      final controller = ThemeController.instance;
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.themeModeName, 'Light Theme');
      expect(controller.isDark, isFalse);

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.themeModeName, 'Dark Theme');
      expect(controller.isDark, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_theme_mode'), 'dark');

      await controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode, ThemeMode.system);
      expect(controller.themeModeName, 'System Default');
      expect(prefs.getString('pref_theme_mode'), 'system');
    });

    test('reloads persisted theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'pref_theme_mode': 'dark'});
      final controller = ThemeController.instance;
      await controller.init();
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDark, isTrue);
    });

    test('defaults to low contrast mode and persists changes', () async {
      final controller = ThemeController.instance;
      expect(controller.isLowContrast, isTrue);

      await controller.setLowContrast(false);
      expect(controller.isLowContrast, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pref_low_contrast'), isFalse);

      await controller.setLowContrast(true);
      expect(controller.isLowContrast, isTrue);
      expect(prefs.getBool('pref_low_contrast'), isTrue);
    });

    test('validates low contrast color tokens for dark and light modes', () {
      // Light Mode low contrast text and soft shadow checks
      expect(AppColors.textPrimary, const Color(0xFF222E3C));
      expect(AppColors.textSecondary, const Color(0xFF4E5E72));
      expect(AppColors.lightShadow, const Color(0xFFF7F9FC));
      expect(AppColors.darkShadow, const Color(0xFFBAC7D5));

      // Dark Mode low contrast text and shadow checks
      expect(AppDarkColors.textPrimary, const Color(0xFFE2E8F0));
      expect(AppDarkColors.textSecondary, const Color(0xFF94A3B8));
      expect(AppDarkColors.darkShadow, const Color(0xFF12151B));
      expect(AppDarkColors.lightShadow, const Color(0xFF282F3C));
    });
  });

  group('Settings Theme Selection Flow', () {
    testWidgets('ProfileScreen displays Theme tile and changes theme mode via dialog',
        (tester) async {
      await ThemeController.instance.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: ProfileScreen(
            audioService: _FakeAudioService(),
            authService: _FakeAuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Settings & Preferences section if needed
      await tester.scrollUntilVisible(
        find.text('Theme'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Verify Theme tile exists and displays Light Theme >
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Light Theme >'), findsOneWidget);

      // Tap the Theme tile
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      // Dialog is displayed with Light Theme, Dark Theme, System Default
      expect(find.text('App Theme'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);

      // Tap Dark Theme option
      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      // ThemeController should now be dark mode
      expect(ThemeController.instance.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_theme_mode'), 'dark');
    });

    testWidgets('ProfileScreen displays Low Contrast Mode tile and toggles it',
        (tester) async {
      await ThemeController.instance.setLowContrast(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: ProfileScreen(
            audioService: _FakeAudioService(),
            authService: _FakeAuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Low Contrast Mode'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Low Contrast Mode'), findsOneWidget);

      await tester.tap(find.text('Low Contrast Mode'));
      await tester.pumpAndSettle();

      expect(ThemeController.instance.isLowContrast, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pref_low_contrast'), isFalse);
    });
  });

  group('Neumorphic dynamic theming', () {
    testWidgets('NeumorphicBox dynamically switches shadows and colors in dark mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: NeumorphicBox(
              child: Text('Test Soft 3D'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.descendant(
        of: find.byType(NeumorphicBox),
        matching: find.byType(Container),
      ).first);

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppDarkColors.background);
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, 2);
      expect(
        decoration.boxShadow![0].color,
        AppDarkColors.lightShadow.withValues(alpha: 0.90),
      );
      expect(
        decoration.boxShadow![1].color,
        AppDarkColors.darkShadow.withValues(alpha: 0.85),
      );
    });
  });

  group('Header Dark Mode Toggle Buttons', () {
    testWidgets('HomeScreen header button toggles dark mode and updates icon/tooltip',
        (tester) async {
      await ThemeController.instance.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: ThemeController.instance,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeController.instance.themeMode,
            home: HomeScreen(
              audioService: _FakeAudioService(),
              authService: _FakeAuthService(),
              onSongTap: (s, [q]) {},
              onPlaylistPlayTap: (p) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the button starts in light mode (showing dark_mode icon to switch to dark)
      final darkButton = find.byTooltip('Switch to Dark Theme');
      expect(darkButton, findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_rounded), findsWidgets);

      // Tap the dark mode button
      await tester.tap(darkButton);
      await tester.pumpAndSettle();

      // ThemeController is now dark mode
      expect(ThemeController.instance.isDark, isTrue);
      expect(ThemeController.instance.themeMode, ThemeMode.dark);

      // Verify button now shows tooltip to switch back to light theme
      expect(find.byTooltip('Switch to Light Theme'), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_rounded), findsWidgets);

      // Tap again to switch back
      await tester.tap(find.byTooltip('Switch to Light Theme'));
      await tester.pumpAndSettle();

      expect(ThemeController.instance.isDark, isFalse);
      expect(ThemeController.instance.themeMode, ThemeMode.light);
      expect(find.byTooltip('Switch to Dark Theme'), findsOneWidget);
    });

    testWidgets('HomeScreen Soft 3D Controls Dark mode switch toggles theme',
        (tester) async {
      await ThemeController.instance.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: ThemeController.instance,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeController.instance.themeMode,
            home: HomeScreen(
              audioService: _FakeAudioService(),
              authService: _FakeAuthService(),
              onSongTap: (s, [q]) {},
              onPlaylistPlayTap: (p) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Neumorphic Soft 3D Controls section
      await tester.scrollUntilVisible(
        find.text('Soft 3D Controls'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Dark mode'), findsOneWidget);

      // Find the switch row next to 'Dark mode'
      final darkModeRow = find.ancestor(
        of: find.text('Dark mode'),
        matching: find.byType(Row),
      );
      final switchFinder = find.descendant(
        of: darkModeRow,
        matching: find.byType(NeumorphicSwitch),
      );
      expect(switchFinder, findsOneWidget);

      // Toggle switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(ThemeController.instance.isDark, isTrue);

      // Toggle switch back
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(ThemeController.instance.isDark, isFalse);
    });

    testWidgets('ProfileScreen header button toggles dark mode',
        (tester) async {
      await ThemeController.instance.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: ThemeController.instance,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeController.instance.themeMode,
            home: ProfileScreen(
              audioService: _FakeAudioService(),
              authService: _FakeAuthService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final toggleFinder = find.byTooltip('Switch to Dark Theme');
      expect(toggleFinder, findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(ThemeController.instance.isDark, isTrue);
      expect(find.byTooltip('Switch to Light Theme'), findsOneWidget);
    });
  });
}
