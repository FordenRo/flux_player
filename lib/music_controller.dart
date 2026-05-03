import 'dart:async';
import 'dart:math';

import 'package:metadata_audio/metadata_audio.dart' as audio_metadata;
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:metadata_audio/metadata_audio.dart' show AudioMetadata;

final audioPlayer = AudioPlayer._internal();
List<AudioTrack> importedTracks = [];

enum LoopMode { playlist, single, none }

class AudioPlayer {
  final _player = media_kit.Player();

  AudioPlayer._internal();

  static final instance = AudioPlayer._internal();

  List<AudioTrack> _queue = [];

  bool get isPlaying => _player.state.playing;
  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  int? get currentIndex => isNotEmpty ? _player.state.playlist.index : null;
  AudioTrack? get currentTrack => isNotEmpty ? queue[currentIndex!] : null;
  List<AudioTrack> get queue => _queue;
  LoopMode get loopMode => switch (_player.state.playlistMode) {
    .loop => .playlist,
    .single => .single,
    .none => .none,
  };
  double get volume => _player.state.volume / 100;
  Duration get duration => _player.state.duration;
  Duration get position => _player.state.position;
  bool get shuffled => _player.state.shuffle;

  final StreamController<List<AudioTrack>> _queueController = .broadcast();

  late final stream = AudioPlayerStream(
    _player.stream.volume.map((e) => e / 100),
    _player.stream.playlist.map((e) => e.index),
    _queueController.stream.distinct(),
    _player.stream.position,
    _player.stream.duration,
    _player.stream.playing,
    _player.stream.shuffle,
    _player.stream.playlist.map((e) => queue[e.index]),
    _player.stream.playlistMode.map(
      (e) => switch (e) {
        .loop => .playlist,
        .single => .single,
        .none => .none,
      },
    ),
  );

  Future<void> setVolume(double volume) async =>
      await _player.setVolume(max(min(volume, 1), 0) * 100);

  Future<void> setShuffled(bool shuffled) async =>
      await _player.setShuffle(shuffled);

  Future<void> setQueue(List<AudioTrack> tracks) async {
    _queue = List.of(tracks);
    _queueController.add(tracks);
    await _player.open(
      media_kit.Playlist(tracks.map((e) => media_kit.Media(e.path)).toList()),
      play: false,
    );
  }

  Future<void> setLoopMode(LoopMode mode) async =>
      await _player.setPlaylistMode(switch (mode) {
        .playlist => .loop,
        .single => .single,
        .none => .single,
      });

  void addToQueue(AudioTrack track) {
    _queue.add(track);
    _queueController.add(queue);
    _player.add(.new(track.path));
  }

  void playNext(AudioTrack track) {
    _queue.insert(currentIndex!, track);
    _queueController.add(queue);
    _player
        .add(.new(track.path))
        .then((_) => _player.move(_queue.length, currentIndex!));
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    _queue = [];
    await _player.stop();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> jump(int index) => _player.jump(index);

  Future<void> next() => _player.next();

  Future<void> previous() => _player.previous();

  Future<void> dispose() async {
    await _player.dispose();
    await _queueController.close();
  }
}

class AudioPlayerStream {
  final Stream<double> volume;
  final Stream<int> currentIndex;
  final Stream<List<AudioTrack>> queue;
  final Stream<Duration> position;
  final Stream<Duration> duration;
  final Stream<bool> isPlaying;
  final Stream<bool> shuffled;
  final Stream<AudioTrack> currentTrack;
  final Stream<LoopMode> loopMode;

  AudioPlayerStream(
    this.volume,
    this.currentIndex,
    this.queue,
    this.position,
    this.duration,
    this.isPlaying,
    this.shuffled,
    this.currentTrack,
    this.loopMode,
  );
}

class AudioTrack {
  final String path;
  final AudioMetadata metadata;

  String get title => metadata.common.title ?? 'Unnamed';
  String get author => metadata.common.artist ?? 'No artist';
  Duration get duration =>
      Duration(milliseconds: (metadata.format.duration ?? 0 * 1000).toInt());
  audio_metadata.Picture? get picture =>
      metadata.common.picture?.nonNulls.first;

  AudioTrack({required this.path, required this.metadata});

  static Future<AudioTrack> fromPath(String path) async {
    final metadata = await audio_metadata.parseFile(path);

    return AudioTrack(path: path, metadata: metadata);
  }
}
