import 'dart:async';
import 'dart:math';

import 'package:metadata_audio/metadata_audio.dart' as audio_metadata;
import 'package:media_kit/media_kit.dart' as media_kit;

final audioPlayer = AudioPlayer._internal();
List<AudioTrack> importedTracks = [];

typedef AudioDevice = media_kit.AudioDevice;
typedef AudioMetadata = audio_metadata.AudioMetadata;
typedef Picture = audio_metadata.Picture;

class AudioPlayer {
  final _player = media_kit.Player();

  AudioPlayer._internal() {
    _player.stream.completed.listen((completed) async {
      if (completed) {
        return _onEnd();
      }
    });
  }

  List<AudioTrack> _queue = [];
  List<int>? _shuffledQueue;
  int? _currentIndex;
  var _shuffled = false;
  var _looped = false;

  bool get isPlaying => _player.state.playing;
  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  int? get currentIndex => _currentIndex;
  List<AudioDevice> get audioDevices => _player.state.audioDevices;
  AudioDevice get audioDevice => _player.state.audioDevice;
  AudioTrack? get currentTrack =>
      currentIndex != null ? queue[currentIndex!] : null;
  List<AudioTrack> get queue => _queue;
  double get volume => _player.state.volume / 100;
  Duration get duration => _player.state.duration;
  Duration get position => _player.state.position;
  bool get shuffled => _shuffled;
  bool get looped => _looped;

  final StreamController<List<AudioTrack>> _queueController = .broadcast();
  final StreamController<int?> _currentIndexController = .broadcast();
  final StreamController<bool> _shuffledController = .broadcast();
  final StreamController<bool> _loopedController = .broadcast();

  late final stream = AudioPlayerStream(
    _player.stream.volume.map((e) => e / 100),
    _currentIndexController.stream.distinct(),
    _queueController.stream.distinct(),
    _player.stream.position,
    _player.stream.duration,
    _player.stream.playing,
    _shuffledController.stream.distinct(),
    _currentIndexController.stream.distinct().map(
      (e) => e != null ? queue[e] : null,
    ),
    _loopedController.stream.distinct(),
  );

  Future<void> setVolume(double volume) async =>
      await _player.setVolume(max(min(volume, 1), 0) * 100);

  void setShuffled(bool shuffled) {
    _shuffled = shuffled;
    _shuffledController.add(shuffled);
    if (shuffled) {
      _shuffledQueue = List.generate(_queue.length, (e) => e)..shuffle();
    } else {
      _shuffledQueue = null;
    }
  }

  void setLooped(bool looped) {
    _looped = looped;
    _loopedController.add(looped);
  }

  Future<void> setQueue(
    List<AudioTrack> tracks, {
    int? index,
    bool play = false,
  }) async {
    _queue = List.of(tracks);
    _queueController.add(tracks);
    if (index != null) {
      await jump(index, play: play);
    } else {
      _currentIndex = null;
      _currentIndexController.add(null);
    }
  }

  void addToQueue(AudioTrack track) {
    _queue.add(track);
    _queueController.add(queue);
  }

  void addNext(AudioTrack track) {
    _queue.insert(currentIndex! + 1, track);
    _queueController.add(queue);
  }

  Future<void> setAudioDevice(AudioDevice device) =>
      _player.setAudioDevice(device);

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() {
    _queue = [];
    _queueController.add([]);
    _currentIndex = null;
    _currentIndexController.add(null);
    return _player.stop();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> jump(int index, {bool play = true}) async {
    if (index < 0 || index >= queue.length) {
      index = 0;
    }
    _currentIndex = index;
    _currentIndexController.add(index);
    await _player.open(media_kit.Media(queue[index].path), play: play);
  }

  Future<void> _onEnd() => looped ? play() : next();

  Future<void> next() => jump(
    shuffled
        ? _shuffledQueue![_shuffledQueue!.indexOf(currentIndex!) + 1]
        : currentIndex! + 1,
  );

  Future<void> previous() => position.inSeconds < 10
      ? jump(
          shuffled
              ? _shuffledQueue![_shuffledQueue!.indexOf(currentIndex!) - 1]
              : currentIndex! - 1,
        )
      : seek(Duration.zero);

  Future<void> dispose() async {
    _shuffledQueue = null;
    await _player.dispose();
    await _queueController.close();
  }
}

class AudioPlayerStream {
  final Stream<double> volume;
  final Stream<int?> currentIndex;
  final Stream<List<AudioTrack>> queue;
  final Stream<Duration> position;
  final Stream<Duration> duration;
  final Stream<bool> isPlaying;
  final Stream<bool> shuffled;
  final Stream<AudioTrack?> currentTrack;
  final Stream<bool> looped;

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
  );
}

class AudioTrack {
  final String path;
  final AudioMetadata metadata;

  String get title => metadata.common.title ?? 'Unnamed';
  String get author => metadata.common.artist ?? 'No artist';
  Duration get duration =>
      Duration(milliseconds: (metadata.format.duration ?? 0 * 1000).toInt());
  Picture? get picture => metadata.common.picture?.nonNulls.first;

  AudioTrack._internal({required this.path, required this.metadata});

  static Future<AudioTrack> fromPath(String path) async {
    final metadata = await audio_metadata.parseFile(path);

    return AudioTrack._internal(path: path, metadata: metadata);
  }
}
