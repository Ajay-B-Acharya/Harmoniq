import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/main.dart';
import 'package:harmoniq/screens/library_screen.dart';
import 'package:harmoniq/services/audio_service.dart';
import 'package:harmoniq/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.example.harmoniq/local_music');

  group('Automatic permissions and local song scanning', () {
    late AudioService audioService;
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkPermission') return false;
        return true;
      });
      audioService = AudioService();
      authService = AuthService();
    });

    tearDown(() {
      audioService.dispose();
      authService.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    testWidgets('SplashScreen asks pre-required permissions on fresh start and scans local songs', (tester) async {
      bool permissionChecked = false;
      bool permissionsRequested = false;
      bool songsFetched = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkPermission') {
          permissionChecked = true;
          // Initially not permitted on fresh download
          return permissionsRequested;
        }
        if (call.method == 'requestAllPermissions') {
          permissionsRequested = true;
          return {
            'storage': true,
            'notification': true,
            'batteryOptimizationsIgnored': false,
            'allGranted': true,
          };
        }
        if (call.method == 'fetchLocalSongs') {
          songsFetched = true;
          return [
            {
              'id': 101,
              'title': 'Downloaded Track',
              'artist': 'Local Artist',
              'album': 'Device Audio',
              'duration': 180000,
              'path': 'content://media/external/audio/media/101',
            }
          ];
        }
        return true;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            authService: authService,
            audioService: audioService,
          ),
        ),
      );

      expect(permissionChecked, isTrue);

      // Advance time past the permission request and splash animation duration
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 7));

      expect(permissionsRequested, isTrue);
      expect(songsFetched, isTrue);
      expect(audioService.localSongs.length, 1);
      expect(audioService.localSongs.first.title, 'Downloaded Track');
    });

    testWidgets('AudioService autoScanIfPermitted scans automatically when permission is granted', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkPermission') return true;
        if (call.method == 'fetchLocalSongs') {
          return [
            {
              'id': 202,
              'title': 'Auto Scanned Song',
              'artist': 'Tester',
              'album': 'Album One',
              'duration': 210000,
              'path': 'content://media/external/audio/media/202',
            }
          ];
        }
        return true;
      });

      expect(audioService.localSongs, isEmpty);
      await audioService.autoScanIfPermitted();

      expect(audioService.localSongs.length, 1);
      expect(audioService.localSongs.first.title, 'Auto Scanned Song');
    });

    testWidgets('Local songs are cached and restored on startup', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkPermission') return true;
        if (call.method == 'fetchLocalSongs') {
          return [
            {
              'id': 303,
              'title': 'Cached Song',
              'artist': 'Singer',
              'album': 'Memory',
              'duration': 150000,
              'path': 'content://media/external/audio/media/303',
            }
          ];
        }
        return true;
      });

      await audioService.scanLocalSongs();
      expect(audioService.localSongs.length, 1);

      // Create a fresh AudioService instance (simulating app relaunch)
      final newAudioService = AudioService();
      await tester.pump(const Duration(milliseconds: 100));
      expect(newAudioService.localSongs.length, 1);
      expect(newAudioService.localSongs.first.title, 'Cached Song');
      newAudioService.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('LibraryScreen shows scanning indicator when audioService.isScanning is true', (tester) async {
      final completer = Completer<List<dynamic>>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkPermission') return true;
        if (call.method == 'fetchLocalSongs') return completer.future;
        return true;
      });

      // Start scan in background
      unawaited(audioService.scanLocalSongs());
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          home: LibraryScreen(
            audioService: audioService,
            initialCategoryIndex: 5, // Local category
            onSongTap: (_) {},
            onFavoriteTap: (_) {},
            onCreatePlaylist: (_) {},
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Scanning device for music...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No local tracks found'), findsOneWidget);
    });
  });
}
