import 'dart:async';
import 'track.dart';
import 'playlist.dart';

class AudioPlayerStream {
  final Stream<double> volume;
  final Stream<int?> currentIndex;
  final Stream<List<Track>> queue;
  final Stream<Duration> position;
  final Stream<Duration> duration;
  final Stream<bool> isPlaying;
  final Stream<bool> shuffled;
  final Stream<Track?> currentTrack;
  final Stream<bool> looped;
  final Stream<Playlist?> currentPlaylist;

  AudioPlayerStream(
    this.volume,
    this.currentIndex,
    this.queue,
    this.position,
    this.duration,
    this.isPlaying,
    this.shuffled,
    this.currentTrack,
    this.looped,
    this.currentPlaylist,
  );
}
