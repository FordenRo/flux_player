import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart'
    show BaseAudioHandler, SeekHandler, MediaItem;
import 'package:audio_session/audio_session.dart' show AudioSession;
import 'package:media_kit/media_kit.dart' as media_kit;
import 'audio_player.dart';
import 'audio_player_stream.dart';
import 'track.dart';
import 'playlist.dart';

class AudioHandlerImpl extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayerImpl.instance;

  AudioHandlerImpl() {
    _init();
  }

  void _init() {
    _player.stream.currentTrack.listen((track) {
      final item = track?.toMediaItem();
      mediaItem.add(item);
      queue.add([item].nonNulls.toList());
      _updateState();
    });
    _player.stream.isPlaying.listen((_) => _updateState());

    _initSession();
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const .music());
  }

  void _updateState() => playbackState.add(
    .new(
      controls: [
        .skipToPrevious,
        _player.isPlaying ? .pause : .play,
        .skipToNext,
        .fastForward,
      ],
      processingState: .idle,
      systemActions: const {.skipToPrevious, .playPause, .skipToNext, .seek},
      androidCompactActionIndices: [0, 1, 2],
      updatePosition: _player.position,
      updateTime: DateTime.now(),
      playing: _player.isPlaying,
      bufferedPosition: _player.duration,
      shuffleMode: _player.shuffled ? .all : .none,
      repeatMode: _player.looped ? .one : .all,
      speed: 1,
      queueIndex: 0,
    ),
  );

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> skipToNext() => _player.next();

  @override
  Future<void> skipToPrevious() => _player.previous();

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}

extension MediaItemAdapter on Track {
  MediaItem toMediaItem() => MediaItem(
    id: 'testid',
    title: title,
    album: '',
    artist: author,
    duration: duration,
  );
}

class AudioPlayerImpl implements AudioPlayer {
  final _player = media_kit.Player();

  static final AudioPlayer instance = AudioPlayerImpl._internal();

  AudioPlayerImpl._internal() {
    _player.stream.completed.listen((completed) async {
      if (completed) {
        return _onEnd();
      }
    });
  }

  List<Track> _queue = [];
  Playlist? _currentPlaylist;
  int? _currentIndex;
  var _shuffled = false;
  var _looped = false;

  @override
  bool get isPlaying => _player.state.playing;
  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  @override
  int? get currentIndex => _currentIndex;
  @override
  List<AudioDevice> get audioDevices => _player.state.audioDevices;
  @override
  AudioDevice get audioDevice => _player.state.audioDevice;
  @override
  Track? get currentTrack => currentIndex != null ? queue[currentIndex!] : null;
  @override
  List<Track> get queue => _queue;
  @override
  Playlist? get currentPlaylist => _currentPlaylist;
  @override
  double get volume => _player.state.volume / 100;
  @override
  Duration get duration => _player.state.duration;
  @override
  Duration get position => _player.state.position;
  @override
  bool get shuffled => _shuffled;
  @override
  bool get looped => _looped;

  final StreamController<List<Track>> _queueController = .broadcast();
  final StreamController<Playlist?> _currentPlaylistController = .broadcast();
  final StreamController<int?> _currentIndexController = .broadcast();
  final StreamController<bool> _shuffledController = .broadcast();
  final StreamController<bool> _loopedController = .broadcast();

  @override
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
    _currentPlaylistController.stream.distinct(),
  );

  @override
  Future<void> setVolume(double volume) async =>
      await _player.setVolume(max(min(volume, 1), 0) * 100);

  @override
  void setShuffled(bool shuffled) {
    if (shuffled) {
      final track = currentTrack;
      _queue.shuffle();
      if (track != null) {
        _currentIndex = _queue.indexOf(track);
        _currentIndexController.add(_currentIndex);
      }
    } else {
      final track = currentTrack;
      _queue = List.of(currentPlaylist?.tracks ?? []);
      if (track != null) {
        _currentIndex = _queue.indexOf(track);
        _currentIndexController.add(_currentIndex);
      }
    }
    _queueController.add(_queue);
    _shuffled = shuffled;
    _shuffledController.add(shuffled);
  }

  @override
  void setLooped(bool looped) {
    _looped = looped;
    _loopedController.add(looped);
  }

  @override
  Future<void> setPlaylist(
    Playlist playlist, {
    int? index,
    bool play = false,
  }) async {
    _currentPlaylist = playlist;
    _currentPlaylistController.add(_currentPlaylist);
    _queue = List.of(playlist.tracks);
    _queueController.add(_queue);
    if (index != null) {
      await jump(index, play: play);
    } else {
      _currentIndex = null;
      _currentIndexController.add(null);
    }
    setShuffled(shuffled);
  }

  @override
  void addToQueue(Track track) {
    _queue.add(track);
    _queueController.add(queue);
  }

  @override
  void addNext(Track track) {
    _queue.insert(currentIndex! + 1, track);
    _queueController.add(queue);
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) =>
      _player.setAudioDevice(device);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() {
    _currentPlaylist = null;
    _currentPlaylistController.add(null);
    _queue = [];
    _queueController.add([]);
    _currentIndex = null;
    _currentIndexController.add(null);
    return _player.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> jump(int index, {bool play = true}) => setIndex(
    shuffled ? queue.indexOf(currentPlaylist!.tracks[index]) : index,
    play: play,
  );

  @override
  Future<void> setIndex(int index, {bool play = true}) {
    if (index < 0 || index >= queue.length) {
      index = 0;
    }
    _currentIndex = index;
    _currentIndexController.add(index);
    return _player.open(media_kit.Media(queue[index].path), play: play);
  }

  Future<void> _onEnd() => looped ? play() : next();

  @override
  Future<void> next() => setIndex(currentIndex! + 1);

  @override
  Future<void> previous() => position.inSeconds > 10
      ? seek(Duration.zero)
      : setIndex(currentIndex! - 1);

  @override
  Future<void> dispose() => Future.wait([
    _player.dispose(),
    _queueController.close(),
    _currentPlaylistController.close(),
    _currentIndexController.close(),
    _shuffledController.close(),
    _loopedController.close(),
  ]);
}
