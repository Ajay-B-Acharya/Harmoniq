import 'youtube_audio_other.dart'
    if (dart.library.io) 'youtube_audio_stream_native.dart'
    as platform;
import 'yt_dlp_channel.dart';

Future<YoutubeAudioStream> resolveYoutubeStream(String videoId) =>
    platform.resolveYoutubeStream(videoId);
