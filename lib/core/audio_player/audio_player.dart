import 'dart:async';

// import 'package:metadata_audio/metadata_audio.dart' as audio_metadata;
import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    as audio_metadata;
import 'package:media_kit/media_kit.dart' as media_kit;

import 'audio_player_impl.dart';
import 'audio_player_stream.dart';
import 'track.dart';
import 'playlist.dart';

final AudioPlayer audioPlayer = AudioPlayerImpl.instance;

typedef AudioDevice = media_kit.AudioDevice;
typedef AudioMetadata = audio_metadata.AudioMetadata;
typedef Picture = audio_metadata.Picture;

abstract interface class AudioPlayer {
  bool get isPlaying;
  int? get currentIndex;
  Track? get currentTrack;
  List<Track> get queue;
  Playlist? get currentPlaylist;
  AudioDevice get audioDevice;
  List<AudioDevice> get audioDevices;
  Duration get position;
  Duration get duration;
  double get volume;
  bool get shuffled;
  bool get looped;
  AudioPlayerStream get stream;

  Future<void> setVolume(double volume);

  Future<void> setShuffled(bool shuffled);

  void setLooped(bool looped);

  Future<void> setPlaylist(Playlist playlist, {int? index, bool play = false});

  void addToQueue(Track track);

  void addNext(Track track);

  Future<void> setAudioDevice(AudioDevice device);

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> next();

  Future<void> previous();

  Future<void> seek(Duration position);

  Future<void> setIndex(int index, {bool play = true});

  Future<void> jump(int index, {bool play = true});

  Future<void> dispose();
}
