import 'song.dart';

/// Represents an individual song playback record stored in Supabase.
class SongHistoryEntry {
  final String id;
  final String userId;
  final String songId;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? artUrl;
  final String source;
  final DateTime playedAt;

  const SongHistoryEntry({
    required this.id,
    required this.userId,
    required this.songId,
    required this.title,
    required this.artist,
    this.album = '',
    this.duration = Duration.zero,
    this.artUrl,
    this.source = 'youtube',
    required this.playedAt,
  });

  /// Converts this database history row into a playable [Song] instance.
  Song toSong() {
    final isYt = source == 'youtube' || songId.startsWith('youtube:');
    final extractedYtId = isYt
        ? (songId.startsWith('youtube:') ? songId.replaceFirst('youtube:', '') : songId)
        : null;

    final gradient = title.codeUnits.fold<int>(
      0,
      (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
    );

    return Song(
      id: 0,
      title: title,
      artist: artist,
      album: album.isNotEmpty ? album : (isYt ? 'YouTube' : 'Music'),
      duration: duration,
      audioPath: isYt ? '' : songId,
      gradientId: gradient,
      albumArtUrl: artUrl,
      source: isYt ? SongSource.youtube : SongSource.local,
      videoId: extractedYtId,
    );
  }

  /// Human-readable relative timestamp (e.g. "Just now", "4m ago", "2h ago").
  String get relativeTime {
    final diff = DateTime.now().toUtc().difference(playedAt.toUtc());
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${playedAt.month}/${playedAt.day}';
  }

  factory SongHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SongHistoryEntry(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      songId: json['song_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String? ?? '',
      duration: Duration(seconds: (json['duration_seconds'] as num?)?.toInt() ?? 0),
      artUrl: json['art_url'] as String?,
      source: json['source'] as String? ?? 'youtube',
      playedAt: json['played_at'] != null
          ? (DateTime.tryParse(json['played_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'song_id': songId,
      'title': title,
      'artist': artist,
      'album': album,
      'duration_seconds': duration.inSeconds,
      if (artUrl != null) 'art_url': artUrl,
      'source': source,
      'played_at': playedAt.toIso8601String(),
    };
  }
}
