import 'dart:io';

import '../models/youtube_video.dart';
import 'yt_dlp_channel.dart';

bool get isSupported => Platform.isAndroid;

Future<List<YoutubeVideo>> searchYoutubeMetadata(String query) =>
    YtDlpChannel.instance.search(query);
