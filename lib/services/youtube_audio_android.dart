import 'yt_dlp_channel.dart';

Future<YoutubeAudioStream> resolveYoutubeStream(String videoId) =>
    YtDlpChannel.instance.resolve(videoId);
