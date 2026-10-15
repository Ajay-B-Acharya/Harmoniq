import '../models/song.dart';

enum LocalSongSort {
  titleAscending,
  titleDescending,
  artistAscending,
  artistDescending,
  albumAscending,
  albumDescending,
  durationAscending,
  durationDescending,
  latestAdded,
  oldestAdded,
}

extension LocalSongSortLabel on LocalSongSort {
  String get shortLabel => switch (this) {
    LocalSongSort.titleAscending => 'Title A–Z',
    LocalSongSort.titleDescending => 'Title Z–A',
    LocalSongSort.artistAscending => 'Artist A–Z',
    LocalSongSort.artistDescending => 'Artist Z–A',
    LocalSongSort.albumAscending => 'Album A–Z',
    LocalSongSort.albumDescending => 'Album Z–A',
    LocalSongSort.durationAscending => 'Duration ↑',
    LocalSongSort.durationDescending => 'Duration ↓',
    LocalSongSort.latestAdded => 'Latest Adds',
    LocalSongSort.oldestAdded => 'Oldest Adds',
  };

  String get label => switch (this) {
    LocalSongSort.titleAscending => 'Title — A to Z',
    LocalSongSort.titleDescending => 'Title — Z to A',
    LocalSongSort.artistAscending => 'Artist — A to Z',
    LocalSongSort.artistDescending => 'Artist — Z to A',
    LocalSongSort.albumAscending => 'Album — A to Z',
    LocalSongSort.albumDescending => 'Album — Z to A',
    LocalSongSort.durationAscending => 'Duration — Shortest first',
    LocalSongSort.durationDescending => 'Duration — Longest first',
    LocalSongSort.latestAdded => 'Date Added — Latest first',
    LocalSongSort.oldestAdded => 'Date Added — Oldest first',
  };
}

List<Song> sortLocalSongs(Iterable<Song> songs, LocalSongSort sort) {
  final sorted = List<Song>.of(songs);
  int compareText(String left, String right) =>
      left.trim().toLowerCase().compareTo(right.trim().toLowerCase());

  int compareWithTitle(
    Song left,
    Song right,
    int Function(Song, Song) compare,
  ) {
    final result = compare(left, right);
    return result == 0 ? compareText(left.title, right.title) : result;
  }

  sorted.sort(
    (left, right) => switch (sort) {
      LocalSongSort.titleAscending => compareText(left.title, right.title),
      LocalSongSort.titleDescending => compareText(right.title, left.title),
      LocalSongSort.artistAscending => compareWithTitle(
        left,
        right,
        (a, b) => compareText(a.artist, b.artist),
      ),
      LocalSongSort.artistDescending => compareWithTitle(
        left,
        right,
        (a, b) => compareText(b.artist, a.artist),
      ),
      LocalSongSort.albumAscending => compareWithTitle(
        left,
        right,
        (a, b) => compareText(a.album, b.album),
      ),
      LocalSongSort.albumDescending => compareWithTitle(
        left,
        right,
        (a, b) => compareText(b.album, a.album),
      ),
      LocalSongSort.durationAscending => compareWithTitle(
        left,
        right,
        (a, b) => a.duration.compareTo(b.duration),
      ),
      LocalSongSort.durationDescending => compareWithTitle(
        left,
        right,
        (a, b) => b.duration.compareTo(a.duration),
      ),
      LocalSongSort.latestAdded => compareWithTitle(
        left,
        right,
        (a, b) => b.id.compareTo(a.id),
      ),
      LocalSongSort.oldestAdded => compareWithTitle(
        left,
        right,
        (a, b) => a.id.compareTo(b.id),
      ),
    },
  );
  return sorted;
}
