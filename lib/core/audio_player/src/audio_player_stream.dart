import 'dart:async';

import '../../models/playlist.dart';
import '../../models/track.dart';

class AudioPlayerStream {
  AudioPlayerStream({
    required this.volume,
    required this.currentIndex,
    required this.queue,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isShuffled,
    required this.currentTrack,
    required this.isLooped,
    required this.currentPlaylist,
  });
  final Stream<double> volume;
  final Stream<int?> currentIndex;
  final Stream<List<Track>> queue;
  final Stream<Duration> position;
  final Stream<Duration> duration;
  final Stream<bool> isPlaying;
  final Stream<bool> isShuffled;
  final Stream<Track?> currentTrack;
  final Stream<bool> isLooped;
  final Stream<Playlist?> currentPlaylist;
}
