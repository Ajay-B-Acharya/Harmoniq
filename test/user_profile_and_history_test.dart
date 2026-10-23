import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harmoniq/models/user_profile.dart';
import 'package:harmoniq/models/song_history_entry.dart';
import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/services/song_history_service.dart';
import 'package:harmoniq/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProfile Model', () {
    test('Default constructor and handle formatting', () {
      const profile = UserProfile(
        id: 'user-123',
        username: 'rachan_dev',
        displayName: 'Rachan Dev',
      );
      expect(profile.handle, '@rachan_dev');
      expect(profile.displayName, 'Rachan Dev');
      expect(profile.formattedListeningTime, '0 sec');
    });

    test('Listening time formatting', () {
      const p1 = UserProfile(
        id: '1',
        username: 'u1',
        displayName: 'U1',
        totalListeningSeconds: 45,
      );
      expect(p1.formattedListeningTime, '45 sec');

      const p2 = UserProfile(
        id: '1',
        username: 'u1',
        displayName: 'U1',
        totalListeningSeconds: 150,
      );
      expect(p2.formattedListeningTime, '2 mins');

      const p3 = UserProfile(
        id: '1',
        username: 'u1',
        displayName: 'U1',
        totalListeningSeconds: 7200,
      );
      expect(p3.formattedListeningTime, '2h');
    });

    test('JSON serialization & deserialization', () {
      final json = {
        'id': 'abc-456',
        'username': 'john_doe',
        'display_name': 'John Doe',
        'avatar_url': 'https://example.com/avatar.png',
        'bio': 'Music lover',
        'favorite_genre': 'Ambient Chill',
        'total_listening_seconds': 3600,
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, 'abc-456');
      expect(profile.username, 'john_doe');
      expect(profile.displayName, 'John Doe');
      expect(profile.bio, 'Music lover');
      expect(profile.favoriteGenre, 'Ambient Chill');
      expect(profile.totalListeningSeconds, 3600);
      expect(profile.formattedListeningTime, '1h');

      final serialized = profile.toJson();
      expect(serialized['id'], 'abc-456');
      expect(serialized['username'], 'john_doe');
      expect(serialized['favorite_genre'], 'Ambient Chill');
    });
  });

  group('SongHistoryEntry Model', () {
    test('Convert to Song and check properties', () {
      final entry = SongHistoryEntry(
        id: 'hist-1',
        userId: 'u1',
        songId: 'vid-xyz',
        title: 'Midnight Echoes',
        artist: 'Harmoniq Studio',
        album: 'YouTube',
        duration: const Duration(seconds: 215),
        artUrl: 'https://img.youtube.com/vi/vid-xyz/hqdefault.jpg',
        source: 'youtube',
        playedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final song = entry.toSong();
      expect(song.title, 'Midnight Echoes');
      expect(song.artist, 'Harmoniq Studio');
      expect(song.duration.inSeconds, 215);
      expect(song.source, SongSource.youtube);
      expect(song.videoId, 'vid-xyz');
      expect(song.albumArtUrl, entry.artUrl);
      expect(entry.relativeTime, '5m ago');
    });

    test('JSON round-trip', () {
      final now = DateTime.now();
      final entry = SongHistoryEntry(
        id: 'e1',
        userId: 'u2',
        songId: 'song-42',
        title: 'Local Melody',
        artist: 'Solo Artist',
        album: 'Local Album',
        duration: const Duration(seconds: 180),
        artUrl: '',
        source: 'local',
        playedAt: now,
      );

      final json = entry.toJson();
      final parsed = SongHistoryEntry.fromJson(json);

      expect(parsed.id, entry.id);
      expect(parsed.userId, entry.userId);
      expect(parsed.title, entry.title);
      expect(parsed.source, 'local');
      expect(parsed.duration.inSeconds, 180);
    });
  });

  group('SongHistoryService & ProfileService Local Caching Fallback', () {
    test('Save and fetch history offline', () async {
      final service = SongHistoryService.instance;
      const testSong = Song(
        id: 101,
        title: 'Offline Dream',
        artist: 'Offline Artist',
        album: 'Cached Beats',
        duration: Duration(seconds: 240),
        audioPath: '/local/path.mp3',
        gradientId: 1,
      );

      // Record offline / unauthenticated
      await service.recordSongPlayback(userId: 'test-user-id', song: testSong);
      final history = await service.fetchUserHistory(userId: 'test-user-id');

      expect(history.isNotEmpty, true);
      expect(history.first.title, 'Offline Dream');
      expect(history.first.artist, 'Offline Artist');
    });

    test('Clear user history offline', () async {
      final service = SongHistoryService.instance;
      await service.clearUserHistory(userId: 'test-user-id');
      final cleared = await service.fetchUserHistory(userId: 'test-user-id');
      expect(cleared.isEmpty, true);
    });

    test('ProfileService update and cached profile', () async {
      final pService = ProfileService.instance;

      final updated = await pService.updateProfile(
        userId: 'user-cached',
        displayName: 'Rachan Pro',
        username: 'rachan_official',
        bio: 'Coding & Music',
        favoriteGenre: 'Lo-Fi',
      );

      expect(updated?.displayName, 'Rachan Pro');
      expect(updated?.username, 'rachan_official');
      expect(updated?.bio, 'Coding & Music');
      expect(updated?.favoriteGenre, 'Lo-Fi');

      final reFetched = await pService.fetchProfile('user-cached');
      expect(reFetched?.displayName, 'Rachan Pro');
      expect(reFetched?.username, 'rachan_official');
    });
  });
}
