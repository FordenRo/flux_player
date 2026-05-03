import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'package:metadata_audio/metadata_audio.dart' as audio_metadata;

final audioPlayer = AudioPlayer._internal();

class AudioPlayer {
  final _player = audioplayers.AudioPlayer();

  AudioPlayer._internal() {
    _player.onDurationChanged.listen((duration) => _duration = duration);
    _player.onPositionChanged.listen((position) => _position = position);
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == .playing;
      _isPlayingController.add(_isPlaying);
      if (state == .completed) {
        next();
      }
    });
  }

  static final instance = AudioPlayer._internal();

  List<AudioTrack> _audioTracks = [];
  List<int>? _shuffledIndeces;
  int? _currentIndex;
  Duration _duration = .zero;
  Duration _position = .zero;
  var _isPlaying = false;
  var _shuffled = false;

  bool get isPlaying => _isPlaying;
  int? get currentIndex => _currentIndex;
  AudioTrack? get currentTrack => audioTracks[currentIndex!];
  List<AudioTrack> get audioTracks => _audioTracks;
  double get volume => _player.volume;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get shuffled => _shuffled;

  final StreamController<int> _currentIndexController = .broadcast();
  final StreamController<double> _volumeController = .broadcast();
  final StreamController<bool> _isPlayingController = .broadcast();
  final StreamController<List<AudioTrack>> _audioTracksController =
      .broadcast();
  final StreamController<bool> _shuffledController = .broadcast();

  late final stream = AudioPlayerStream(
    _volumeController.stream.distinct(),
    _currentIndexController.stream.distinct(),
    _audioTracksController.stream.distinct(),
    _player.onPositionChanged.distinct(),
    _player.onDurationChanged.distinct(),
    _isPlayingController.stream.distinct(),
    _shuffledController.stream.distinct(),
    _currentIndexController.stream.distinct().map((e) => audioTracks[e]),
  );

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
    _volumeController.add(volume);
  }

  void setShuffled(bool shuffled) {
    if (shuffled) {
      _shuffledIndeces = List.generate(audioTracks.length, (e) => e)..shuffle();
    } else {
      _shuffledIndeces = null;
    }
    _shuffled = shuffled;
    _shuffledController.add(shuffled);
  }

  void setAudioTrack(AudioTrack track) => setAudioTracks([track]);

  void setAudioTracks(List<AudioTrack> tracks) {
    _audioTracks = tracks;
    _audioTracksController.add(tracks);
    jump(0);
  }

  void addAudioTrack(AudioTrack track) {
    _audioTracks.add(track);
    _audioTracksController.add(audioTracks);
  }

  Future<void> play() async => await _player.resume();

  Future<void> pause() async => await _player.pause();

  Future<void> stop() async {
    _currentIndex = null;
    _audioTracks = [];
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> jump(int index) async {
    _currentIndex = index;
    await _player.setSourceDeviceFile(audioTracks[index].path);
    _currentIndexController.add(index);
  }

  Future<void> next() async {
    await jump(
      !shuffled
          ? currentIndex! + 1
          : _shuffledIndeces![_shuffledIndeces!.indexOf(currentIndex!) + 1],
    );
    if (isPlaying) {
      await _player.resume();
    }
  }

  Future<void> previous() async {
    await jump(
      !shuffled
          ? currentIndex! + 1
          : _shuffledIndeces![_shuffledIndeces!.indexOf(currentIndex!) - 1],
    );
    if (isPlaying) {
      await _player.resume();
    }
  }
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
  final audio_metadata.AudioMetadata metadata;

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

class Playlist {
  final List<AudioTrack> tracks;

  Playlist({required this.tracks});
}
