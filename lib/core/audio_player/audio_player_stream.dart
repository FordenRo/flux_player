import 'dart:async';

import '../models/playlist.dart';
import '../models/track.dart';

class AudioPlayerStream {
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
}
