import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/services/youtube_service.dart';
import 'package:harmoniq/services/yt_dlp_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.example.harmoniq/yt_dlp');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('search maps bounded metadata and omits invalid identities', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'search');
      expect(call.arguments, {'query': 'jazz', 'limit': 10});
      return [
        {
          'id': 'abcdefghijk',
          'title': 'Jazz',
          'artist': 'Channel',
          'thumbnail': 'https://img.example/art',
          'duration': 150.5,
        },
        {'id': 'invalid', 'title': 'Bad'},
      ];
    });
    final results = await YtDlpChannel.instance.search('jazz');
    expect(results, hasLength(1));
    expect(results.single.duration, const Duration(milliseconds: 150500));
    expect(results.single.thumbnailUrl, 'https://img.example/art');
    expect(() => results.clear(), throwsUnsupportedError);
  });

  test('selected stream preserves safe transient playback headers', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'resolve');
      expect(call.arguments, {'id': 'abcdefghijk'});
      return {
        'id': 'abcdefghijk',
        'streamUrl': 'https://audio.example/stream?token=secret',
        'headers': {
          'User-Agent': 'Player',
          'Referer': 'https://www.youtube.com/',
          'Authorization': 'excluded',
        },
      };
    });
    final stream = await YtDlpChannel.instance.resolve('abcdefghijk');
    expect(stream.uri.host, 'audio.example');
    expect(stream.headers, {
      'User-Agent': 'Player',
      'Referer': 'https://www.youtube.com/',
    });
  });

  test('rejects invalid input and masks extraction errors', () async {
    await expectLater(
      YtDlpChannel.instance.resolve('bad'),
      throwsFormatException,
    );
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(
        code: 'EXTRACTION_FAILED',
        message: 'https://audio.example/secret?token=value',
      ),
    );
    await expectLater(
      YtDlpChannel.instance.resolve('abcdefghijk'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          isNot(contains('secret')),
        ),
      ),
    );
    await expectLater(
      YtDlpChannel.instance.search('jazz'),
      throwsA(
        isA<YoutubeSourceException>().having(
          (e) => e.message,
          'message',
          isNot(contains('secret')),
        ),
      ),
    );
  });
}
