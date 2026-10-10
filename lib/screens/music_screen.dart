import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/youtube_video.dart';
import '../services/audio_service.dart';
import 'explore_screen.dart';

/// Legacy alias for ExploreScreen. Maintains backwards compatibility.
class MusicScreen extends StatelessWidget {
  final AudioService audioService;
  final Function(Song, [List<Song>? queue]) onSongTap;
  final Function(Song) onFavoriteTap;
  final ValueChanged<String>? onSearchTap;
  final Future<List<YoutubeVideo>> Function()? loadVideos;

  const MusicScreen({
    super.key,
    required this.audioService,
    required this.onSongTap,
    required this.onFavoriteTap,
    this.onSearchTap,
    this.loadVideos,
  });

  @override
  Widget build(BuildContext context) {
    return ExploreScreen(
      audioService: audioService,
      onSongTap: onSongTap,
      onFavoriteTap: onFavoriteTap,
      onSearchTap: onSearchTap,
      loadVideos: loadVideos,
    );
  }
}
