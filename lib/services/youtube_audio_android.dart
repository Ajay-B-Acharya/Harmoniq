import 'yt_dlp_channel.dart';

Future<YoutubeAudioStream> resolveYoutubeStream(
  String videoId, {
  String? quality,
}) => YtDlpChannel.instance.resolve(videoId, quality: quality);

