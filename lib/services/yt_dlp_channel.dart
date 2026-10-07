import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/youtube_video.dart';
import 'youtube_service.dart';

class YoutubeAudioStream {
  final Uri uri;
  final Map<String, String> headers;

  const YoutubeAudioStream(this.uri, {this.headers = const {}});
}

class YtDlpChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.example.harmoniq/yt_dlp',
  );
  static final YtDlpChannel instance = YtDlpChannel();

  Future<List<YoutubeVideo>> search(String query) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const YoutubeSourceException('On-device search requires Android.');
    }
    if (query.trim().isEmpty || query.length > 200) {
      throw const YoutubeSourceException(
        'Please use a search of 200 characters or fewer.',
      );
    }
    try {
      final entries = await _channel.invokeListMethod<Object?>('search', {
        'query': query,
        'limit': 10,
      });
      return List.unmodifiable(
        (entries ?? const []).whereType<Map>().map((entry) {
          final id = entry['id'];
          if (id is! String || !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) {
            return null;
          }
          final image = Uri.tryParse(entry['thumbnail'] as String? ?? '');
          final seconds = entry['duration'];
          return YoutubeVideo(
            id: id,
            title: (entry['title'] as String?)?.trim().isNotEmpty == true
                ? entry['title'] as String
                : 'Untitled video',
            artist: (entry['artist'] as String?)?.trim().isNotEmpty == true
                ? entry['artist'] as String
                : 'Unknown channel',
            thumbnailUrl:
                image?.scheme == 'https' && image?.host.isNotEmpty == true
                ? image.toString()
                : '',
            duration: seconds is num && seconds.isFinite && seconds > 0
                ? Duration(milliseconds: (seconds * 1000).round())
                : Duration.zero,
          );
        }).whereType<YoutubeVideo>(),
      );
    } catch (_) {
      throw const YoutubeSourceException(
        'YouTube public metadata is unavailable. Please try again later.',
      );
    }
  }

  Future<YoutubeAudioStream> resolve(String id) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('On-device YouTube audio requires Android.');
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) {
      throw const FormatException('Invalid YouTube video ID.');
    }
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'resolve',
        {'id': id},
      );
      if (result?['id'] != id) {
        throw const FormatException('Unexpected video identity.');
      }
      final uri = Uri.tryParse(result?['streamUrl'] as String? ?? '');
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw const FormatException('Invalid audio stream.');
      }
      final headers = <String, String>{};
      final rawHeaders = result?['headers'];
      if (rawHeaders is Map) {
        for (final name in ['User-Agent', 'Referer']) {
          final value = rawHeaders[name];
          if (value is String &&
              value.isNotEmpty &&
              !value.contains('\r') &&
              !value.contains('\n')) {
            headers[name] = value;
          }
        }
      }
      return YoutubeAudioStream(uri, headers: Map.unmodifiable(headers));
    } catch (_) {
      throw StateError('YouTube audio is unavailable. Please try again.');
    }
  }
}
