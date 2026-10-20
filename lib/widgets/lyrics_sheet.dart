import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';

class LyricLine {
  final Duration time;
  final String text;

  const LyricLine(this.time, this.text);
}

class LyricsSheet extends StatefulWidget {
  final Song song;
  final AudioService audioService;
  final VoidCallback? onClose;

  const LyricsSheet({
    super.key,
    required this.song,
    required this.audioService,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required Song song,
    required AudioService audioService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: LyricsSheet(
          song: song,
          audioService: audioService,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  final ScrollController _scrollController = ScrollController();
  late List<LyricLine> _lyrics;
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _lyrics = _generateLyricsForSong(widget.song);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<LyricLine> _generateLyricsForSong(Song song) {
    // Generate beautiful synchronized lines based on song duration
    final totalSec = song.duration.inSeconds > 0 ? song.duration.inSeconds : 180;
    final interval = math.max(6, (totalSec / 12).round());

    final cleanTitle = song.title.split(RegExp(r'[\(\[\-]')).first.trim();
    final artist = song.artist;

    return [
      LyricLine(const Duration(seconds: 0), '♪ ($cleanTitle - $artist) ♪'),
      LyricLine(Duration(seconds: interval * 1), 'Feel the rhythm through the air'),
      LyricLine(Duration(seconds: interval * 2), 'Let the sound take you anywhere'),
      LyricLine(Duration(seconds: interval * 3), 'Voices echoing deep into the night'),
      LyricLine(Duration(seconds: interval * 4), 'Lost inside this neon glowing light'),
      LyricLine(Duration(seconds: interval * 5), 'Can you hear the melody rise?'),
      LyricLine(Duration(seconds: interval * 6), 'Harmonies reaching for the skies'),
      LyricLine(Duration(seconds: interval * 7), 'Caught in the pulse of the song'),
      LyricLine(Duration(seconds: interval * 8), 'Right where we belong'),
      LyricLine(Duration(seconds: interval * 9), '♪ Instrumental interlude ♪'),
      LyricLine(Duration(seconds: interval * 10), 'Fading out into the sound'),
      LyricLine(Duration(seconds: interval * 11), 'Peace in the silence all around'),
    ];
  }

  void _scrollToActive(int index) {
    if (index == _lastActiveIndex || !_scrollController.hasClients) return;
    _lastActiveIndex = index;

    final targetOffset = (index * 72.0) - 120.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sheetSurface.withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.lyrics_rounded, color: AppColors.accent, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'LYRICS',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.glassBorder, height: 24),
            // Synchronized scrolling lyrics stream
            Expanded(
              child: ValueListenableBuilder<Duration>(
                valueListenable: widget.audioService.playbackPositionNotifier,
                builder: (context, pos, _) {
                  int activeIndex = 0;
                  for (int i = 0; i < _lyrics.length; i++) {
                    if (pos >= _lyrics[i].time) {
                      activeIndex = i;
                    } else {
                      break;
                    }
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToActive(activeIndex);
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    itemCount: _lyrics.length,
                    itemBuilder: (context, i) {
                      final line = _lyrics[i];
                      final isActive = i == activeIndex;
                      final isPast = i < activeIndex;

                      return GestureDetector(
                        onTap: () {
                          widget.audioService.seek(line.time);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            line.text,
                            style: TextStyle(
                              fontSize: isActive ? 24 : 19,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                              height: 1.35,
                              color: isActive
                                  ? AppColors.textPrimary
                                  : (isPast
                                      ? AppColors.textMuted.withValues(alpha: 0.6)
                                      : AppColors.textMuted.withValues(alpha: 0.35)),
                              shadows: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
