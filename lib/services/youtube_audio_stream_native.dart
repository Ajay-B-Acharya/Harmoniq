import 'dart:io';

import 'youtube_audio_android.dart' as android;
import 'youtube_audio_other.dart' as other;
import 'yt_dlp_channel.dart';

Future<YoutubeAudioStream> resolveYoutubeStream(String videoId) =>
    Platform.isAndroid
    ? android.resolveYoutubeStream(videoId)
    : other.resolveYoutubeStream(videoId);
