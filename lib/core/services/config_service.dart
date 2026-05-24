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
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/Flux Player/config');
  if (!file.existsSync()) {
    return;
  }
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
  var hasMainPlaylist = false;
  try {
    hasMainPlaylist = stream.readBool();
  } catch (_) {}
  final mainPlaylistIdx = hasMainPlaylist ? stream.read(8) : null;
  var themeColorIdx = 0;
  try {
    themeColorIdx = stream.read(5);
  } catch (_) {}

  Future.delayed(
    const Duration(milliseconds: 10),
    () => windowManager.setPosition(Offset(wPosX, wPosY)),
  );
  await audioPlayer.setVolume(volume);
  audioPlayer
    ..setShuffled(shuffled)
    ..setLooped(looped);
  appController.currentPage = AppPages.values[pageIndex];

  final tracksFile = File('${dir.path}/Flux Player/tracks');
  if (!tracksFile.existsSync()) {
    return;
  }
  final tracksStream = BitStream(bytes: await tracksFile.readAsBytes());

  final importedTracks = await Isolate.run(() {
    final tracks = <Track>[];
    while (tracksStream.length > tracksStream.cursor) {
      tracks.add(_loadTrack(tracksStream));
    }
    return tracks;
  });

  importedPlaylist.tracks = importedTracks;

  final playlistsFile = File('${dir.path}/Flux Player/playlists');
  if (!playlistsFile.existsSync()) {
    return;
  }
  final playlistsStream = BitStream(bytes: await playlistsFile.readAsBytes());

  final playlistsCount = playlistsStream.read(8);
  playlists = List.generate(
    playlistsCount,
    (_) => _loadPlaylist(playlistsStream, tracks: importedTracks),
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
  appTheme.seedColor = seedColors[themeColorIdx % 5];

  await Future.microtask(() async {
    await audioPlayer.setAudioDevice(
      audioPlayer.audioDevices.firstWhere(
        (e) => e.name == deviceName,
        orElse: () => audioPlayer.audioDevice,
      ),
    );
  });

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
}

Future<void> saveConfiguration() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/Flux Player/config');
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
  final playingIndex = wasPlayingPlaylist
      ? shuffled
            ? audioPlayer.currentPlaylist!.tracks.indexOf(
                audioPlayer.currentTrack!,
              )
            : audioPlayer.currentIndex!
      : null;
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

  final tracksFile = File('${dir.path}/Flux Player/tracks');
  await tracksFile.create(recursive: true);
  final tracksStream = BitStream();

  for (final track in importedPlaylist.tracks) {
    _saveTrack(tracksStream, track);
  }
  await tracksFile.writeAsBytes(tracksStream.toBytes());

  final playlistsFile = File('${dir.path}/Flux Player/playlists');
  await playlistsFile.create(recursive: true);
  final playlistsStream = BitStream()..write(playlists.length, 8);
  for (final playlist in playlists) {
    _savePlaylist(playlistsStream, playlist, tracks: importedPlaylist.tracks);
  }
  await playlistsFile.writeAsBytes(playlistsStream.toBytes());
}

Track _loadTrack(BitStream stream) {
  final path = stream.readString(8);
  return Track.fromPath(path);
}

void _saveTrack(BitStream stream, Track track) {
  stream.writeString(track.path, 8);
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
