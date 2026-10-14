import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/models/song.dart';
import 'package:harmoniq/utils/local_song_sort.dart';

Song _song({
  required int id,
  required String title,
  required String artist,
  required String album,
  required int seconds,
}) => Song(
  id: id,
  title: title,
  artist: artist,
  album: album,
  duration: Duration(seconds: seconds),
  audioPath: '/music/$id.mp3',
  gradientId: id,
);

void main() {
  final songs = [
    _song(
      id: 1,
      title: 'zebra',
      artist: 'Delta',
      album: 'Second',
      seconds: 220,
    ),
    _song(id: 2, title: 'Alpha', artist: 'bravo', album: 'Third', seconds: 90),
    _song(id: 3, title: 'Moon', artist: 'Alpha', album: 'First', seconds: 160),
  ];

  test('sorts local songs alphabetically without case sensitivity', () {
    expect(
      sortLocalSongs(
        songs,
        LocalSongSort.titleAscending,
      ).map((song) => song.id),
      [2, 3, 1],
    );
    expect(
      sortLocalSongs(
        songs,
        LocalSongSort.titleDescending,
      ).map((song) => song.id),
      [1, 3, 2],
    );
    expect(
      sortLocalSongs(
        songs,
        LocalSongSort.artistAscending,
      ).map((song) => song.id),
      [3, 2, 1],
    );
    expect(
      sortLocalSongs(
        songs,
        LocalSongSort.artistDescending,
      ).map((song) => song.id),
      [1, 2, 3],
    );
    expect(
      sortLocalSongs(
        songs,
        LocalSongSort.albumAscending,
      ).map((song) => song.id),
      [3, 1, 2],
    );
    expect(
      sortLocalSongs(
        songs,
        LocalSongSort.albumDescending,
      ).map((song) => song.id),
      [2, 1, 3],
    );
  });

  test('sorts local songs by duration without mutating the source list', () {
    expect(
      sortLocalSongs(
        songs,
        LocalSongSort.durationAscending,
      ).map((song) => song.id),
      [2, 3, 1],
    );
    expect(
      sortLocalSongs(
        songs,
        LocalSongSort.durationDescending,
      ).map((song) => song.id),
      [1, 3, 2],
    );
    expect(songs.map((song) => song.id), [1, 2, 3]);
  });
}
