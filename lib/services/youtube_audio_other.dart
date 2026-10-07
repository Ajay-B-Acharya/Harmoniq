import 'yt_dlp_channel.dart';

Future<YoutubeAudioStream> resolveYoutubeStream(String videoId) async {
  if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(videoId)) {
    throw const FormatException('Invalid YouTube video ID.');
  }
  throw UnsupportedError('On-device YouTube audio requires Android.');
}
