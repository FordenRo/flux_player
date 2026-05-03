import 'dart:async';

import 'package:metadata_audio/metadata_audio.dart' as audio_metadata;
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:metadata_audio/metadata_audio.dart' show AudioMetadata;

final audioPlayer = AudioPlayer._internal();

class AudioPlayer {
  // final _player = audioplayers.AudioPlayer();
  final _player = media_kit.Player();

  AudioPlayer._internal();

  static final instance = AudioPlayer._internal();

  List<AudioTrack> _audioTracks = [];

  bool get isPlaying => _player.state.playing;
  bool get isEmpty => _audioTracks.isEmpty;
  bool get isNotEmpty => _audioTracks.isNotEmpty;
  int? get currentIndex => isNotEmpty ? _player.state.playlist.index : null;
  AudioTrack? get currentTrack =>
      isNotEmpty ? audioTracks[currentIndex!] : null;
  List<AudioTrack> get audioTracks => _audioTracks;
  double get volume => _player.state.volume / 100;
  Duration get duration => _player.state.duration;
  Duration get position => _player.state.position;
  bool get shuffled => _player.state.shuffle;

  final StreamController<int> _currentIndexController = .broadcast();
  final StreamController<List<AudioTrack>> _audioTracksController =
      .broadcast();

  late final stream = AudioPlayerStream(
    _player.stream.volume.map((e) => e / 100),
    _player.stream.playlist.map((e) => e.index),
    _audioTracksController.stream.distinct(),
    _player.stream.position,
    _player.stream.duration,
    _player.stream.playing,
    _player.stream.shuffle,
    _currentIndexController.stream.distinct().map((e) => audioTracks[e]),
  );

  Future<void> setVolume(double volume) async =>
      await _player.setVolume(volume * 100);

  Future<void> setShuffled(bool shuffled) async =>
      await _player.setShuffle(shuffled);

  void setAudioTrack(AudioTrack track) => setAudioTracks([track]);

  void setAudioTracks(List<AudioTrack> tracks) {
    _audioTracks = tracks;
    _audioTracksController.add(tracks);
    _player.open(
      media_kit.Playlist(tracks.map((e) => media_kit.Media(e.path)).toList()),
    );
    jump(0);
  }

  void addAudioTrack(AudioTrack track) {
    _audioTracks.add(track);
    _audioTracksController.add(audioTracks);
  }

  Future<void> play() async => await _player.play();

  Future<void> pause() async => await _player.pause();

  Future<void> stop() async {
    _audioTracks = [];
    await _player.stop();
  }

  Future<void> seek(Duration position) async => await _player.seek(position);

  Future<void> jump(int index) async => await _player.jump(index);

  Future<void> next() async => await _player.next();

  Future<void> previous() async => await _player.previous();
}

class AudioPlayerStream {
  final Stream<double> volume;
  final Stream<int> currentIndex;
  final Stream<List<AudioTrack>> audioTracks;
  final Stream<Duration> position;
  final Stream<Duration> duration;
  final Stream<bool> isPlaying;
  final Stream<bool> shuffled;
  final Stream<AudioTrack> currentTrack;

  AudioPlayerStream(
    this.volume,
    this.currentIndex,
    this.audioTracks,
    this.position,
    this.duration,
    this.isPlaying,
    this.shuffled,
    this.currentTrack,
  );
}

class AudioTrack {
  final String path;
  final AudioMetadata metadata;

  String get title => metadata.common.title ?? 'Unnamed';
  String get author => metadata.common.artist ?? 'No artist';
  Duration get duration =>
      Duration(milliseconds: (metadata.format.duration ?? 0 * 1000).toInt());
  audio_metadata.Picture? get picture => metadata.common.picture?.first;

  AudioTrack({required this.path, required this.metadata});

  static Future<AudioTrack> fromPath(String path) async {
    final metadata = await audio_metadata.parseFile(path);
    return AudioTrack(path: path, metadata: metadata);
  }
}
