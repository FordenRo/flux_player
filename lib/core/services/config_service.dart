import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/app_controller.dart';
import '../audio_player/audio_player.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../theme/theme.dart';
import '../utils/bitstream.dart';

Playlist importedPlaylist = .new(title: 'Imported');
Playlist? mainPlaylist;
List<Playlist> playlists = [];

Future<void> loadConfiguration() async {
  final path = '${(await getApplicationDocumentsDirectory()).path}/Flux Player';

  final file = File('$path/config');
  if (!file.existsSync()) return;

  final stream = BitStream(bytes: await file.readAsBytes());

  final wPosX = stream.read(16).toDouble() - 32768;
  final wPosY = stream.read(16).toDouble() - 32768;
  final volume = stream.read(8) / 255;
  final pageIndex = stream.read(8);
  final shuffled = stream.readBool();
  final looped = stream.readBool();
  final wasPlayingPlaylist = stream.readBool();
  final playingPlaylistIdx = wasPlayingPlaylist ? stream.read(8) : null;
  final playingIndex = wasPlayingPlaylist ? stream.read(16) : null;
  final deviceName = stream.readString(6);
  final position = stream.read(10) / 255;
  final hasMainPlaylist = stream.readBool();
  final mainPlaylistIdx = hasMainPlaylist ? stream.read(8) : null;
  final themeColorIdx = stream.read(5);

  _setWindowPosition(wPosX, wPosY);

  await audioPlayer.setVolume(volume);
  audioPlayer
    ..setShuffled(shuffled, shuffleQueue: false)
    ..setLooped(looped);

  await _loadImportedTracks(path);
  await _loadPlaylists(
    path,
    wasPlayingPlaylist: wasPlayingPlaylist,
    playingPlaylistIdx: playingPlaylistIdx,
    playingIndex: playingIndex,
    hasMainPlaylist: hasMainPlaylist,
    mainPlaylistIdx: mainPlaylistIdx,
  );
  await _loadQueue(path, playingIndex: playingIndex);

  appTheme.seedColor = seedColors[themeColorIdx % 5];
  appController.currentPage = AppPages.values[pageIndex];

  await _setAudioDevice(deviceName);

  _setPlayerPosition(position);
}

void _setWindowPosition(double x, double y) => Future.delayed(
  const Duration(milliseconds: 10),
  () => windowManager.setPosition(Offset(x, y)),
);

Future<void> _loadImportedTracks(String dir) async {
  final tracksFile = File('$dir/tracks');
  if (!tracksFile.existsSync()) return;

  final tracksStream = BitStream(bytes: await tracksFile.readAsBytes());

  final importedTracks = await Isolate.run(() {
    final tracks = <Track>[];
    while (tracksStream.length > tracksStream.cursor) {
      tracks.add(_loadTrack(tracksStream));
    }
    return tracks;
  });

  importedPlaylist.tracks = importedTracks;
}

Track _loadTrack(BitStream stream) {
  final path = stream.readString(8);
  return Track.fromPath(path);
}

Future<void> _loadPlaylists(
  String dir, {
  required bool wasPlayingPlaylist,
  required bool hasMainPlaylist,
  int? mainPlaylistIdx,
  int? playingPlaylistIdx,
  int? playingIndex,
}) async {
  final playlistsFile = File('$dir/playlists');
  if (!playlistsFile.existsSync()) return;

  final playlistsStream = BitStream(bytes: await playlistsFile.readAsBytes());

  final playlistsCount = playlistsStream.read(8);
  playlists = List.generate(
    playlistsCount,
    (_) => _loadPlaylist(playlistsStream, tracks: importedPlaylist.tracks),
  );

  if (wasPlayingPlaylist) {
    final playlist = playingPlaylistIdx! == 255
        ? importedPlaylist
        : playlists.elementAtOrNull(playingPlaylistIdx);
    if (playlist != null) {
      await audioPlayer.setPlaylist(playlist, index: playingIndex);
    }
  }

  if (hasMainPlaylist) {
    mainPlaylist = playlists.elementAtOrNull(mainPlaylistIdx!);
  }
}

Playlist _loadPlaylist(BitStream stream, {required List<Track> tracks}) {
  final title = stream.readString(6);
  final trackCount = stream.read(16);
  final trackIndices = List.generate(trackCount, (_) => stream.read(16));
  return Playlist(
    title: title,
    tracks: trackIndices
        .map((idx) => tracks.elementAtOrNull(idx))
        .nonNulls
        .toList(),
  );
}

Future<void> _loadQueue(String path, {int? playingIndex}) async {
  final queueFile = File('$path/queue');
  if (!queueFile.existsSync()) return;

  final queueStream = BitStream(bytes: await queueFile.readAsBytes());

  final tracks = <Track?>[];
  while (queueStream.length > queueStream.cursor) {
    tracks.add(importedPlaylist.tracks.elementAtOrNull(queueStream.read(16)));
  }
  final queue = tracks.nonNulls.toList();
  await audioPlayer.setQueue(queue, index: playingIndex);
}

Future<void> _setAudioDevice(String name) => Future.microtask(() async {
  await audioPlayer.setAudioDevice(
    audioPlayer.audioDevices.firstWhere(
      (e) => e.name == name,
      orElse: () => audioPlayer.audioDevice,
    ),
  );
});

void _setPlayerPosition(double position) =>
    Future.delayed(const Duration(milliseconds: 100), () {
      if (audioPlayer.currentTrack != null) {
        return audioPlayer.seek(
          Duration(
            milliseconds: (audioPlayer.duration.inMilliseconds * position)
                .toInt(),
          ),
        );
      }
    });

Future<void> saveConfiguration() async {
  final path = '${(await getApplicationDocumentsDirectory()).path}/Flux Player';

  final file = File('$path/config');
  await file.create(recursive: true);

  final stream = BitStream();

  final wPos = await windowManager.getPosition();
  final wPosX = wPos.dx;
  final wPosY = wPos.dy;
  final volume = audioPlayer.volume;
  final pageIndex = appController.currentPage.index;
  final shuffled = audioPlayer.shuffled;
  final looped = audioPlayer.looped;
  final wasPlayingPlaylist = audioPlayer.currentPlaylist != null;
  final playingPlaylistIdx = wasPlayingPlaylist
      ? audioPlayer.currentPlaylist! == importedPlaylist
            ? 255
            : playlists.indexOf(audioPlayer.currentPlaylist!)
      : null;
  final playingIndex = audioPlayer.currentIndex;
  final deviceName = audioPlayer.audioDevice.name;
  final position = audioPlayer.duration.inMilliseconds > 0
      ? audioPlayer.position.inMilliseconds /
            audioPlayer.duration.inMilliseconds
      : 0.0;
  final hasMainPlaylist = mainPlaylist != null;

  stream
    ..write(wPosX.toInt() + 32768, 16)
    ..write(wPosY.toInt() + 32768, 16)
    ..write((volume * 255).toInt(), 8)
    ..write(pageIndex, 8)
    ..writeBool(shuffled)
    ..writeBool(looped)
    ..writeBool(wasPlayingPlaylist);
  if (wasPlayingPlaylist) {
    stream
      ..write(playingPlaylistIdx!, 8)
      ..write(playingIndex!, 16);
  }
  stream
    ..writeString(deviceName, 6)
    ..write((position * 255).toInt(), 10)
    ..writeBool(hasMainPlaylist);
  if (hasMainPlaylist) {
    stream.write(playlists.indexOf(mainPlaylist!), 8);
  }
  stream.write(seedColors.indexOf(appTheme.seedColor), 5);
  await file.writeAsBytes(stream.toBytes());

  await _saveImportedTracks(path);
  await _savePlaylists(path);
  await _saveQueue(path);
}

Future<void> _saveImportedTracks(String path) async {
  final tracksFile = File('$path/tracks');
  await tracksFile.create(recursive: true);

  final tracksStream = BitStream();

  for (final track in importedPlaylist.tracks) {
    _saveTrack(tracksStream, track);
  }
  await tracksFile.writeAsBytes(tracksStream.toBytes());
}

void _saveTrack(BitStream stream, Track track) {
  stream.writeString(track.path, 8);
}

Future<void> _savePlaylists(String path) async {
  final playlistsFile = File('$path/playlists');
  await playlistsFile.create(recursive: true);

  final playlistsStream = BitStream()..write(playlists.length, 8);

  for (final playlist in playlists) {
    _savePlaylist(playlistsStream, playlist, tracks: importedPlaylist.tracks);
  }
  await playlistsFile.writeAsBytes(playlistsStream.toBytes());
}

void _savePlaylist(
  BitStream stream,
  Playlist playlist, {
  required List<Track> tracks,
}) {
  stream.writeString(playlist.title, 6);
  final mappedTracks = playlist.tracks
      .map((track) => tracks.indexOf(track))
      .where((idx) => idx != -1);
  stream.write(mappedTracks.length, 16);
  for (final idx in mappedTracks) {
    stream.write(idx, 16);
  }
}

Future<void> _saveQueue(String path) async {
  final queueFile = File('$path/queue');
  await queueFile.create(recursive: true);

  final queueStream = BitStream();

  for (final trackIdx
      in audioPlayer.queue
          .map((e) => importedPlaylist.tracks.indexOf(e))
          .where((e) => e != -1)) {
    queueStream.write(trackIdx, 16);
  }
  await queueFile.writeAsBytes(queueStream.toBytes());
}
