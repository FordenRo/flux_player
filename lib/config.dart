import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'audio_player.dart';
import 'pages/main_page.dart';
import 'utils/bitstream.dart';

Playlist importedPlaylist = .new(title: 'Imported');
Playlist? mainPlaylist;
List<Playlist> playlists = [];

Future<void> loadConfiguration() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/Flux Player/config');
  if (!await file.exists()) {
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

  await windowManager.setPosition(Offset(wPosX, wPosY));
  await audioPlayer.setVolume(volume);
  audioPlayer.setShuffled(shuffled);
  audioPlayer.setLooped(looped);
  mainPageController.pageIndex = pageIndex;

  final tracksFile = File('${dir.path}/Flux Player/tracks');
  if (!await tracksFile.exists()) {
    return;
  }
  final tracksStream = BitStream(bytes: await tracksFile.readAsBytes());

  final importedTracks = await Isolate.run(() {
    var tracks = <AudioTrack>[];
    while (tracksStream.length > tracksStream.cursor) {
      tracks.add(_loadTrack(tracksStream));
    }
    return tracks;
  });

  importedPlaylist.tracks = importedTracks;

  final playlistsFile = File('${dir.path}/Flux Player/playlists');
  if (!await playlistsFile.exists()) {
    return;
  }
  final playlistsStream = BitStream(bytes: await playlistsFile.readAsBytes());

  playlists = await Isolate.run(() {
    var playlists = <Playlist>[];
    while (playlistsStream.length > playlistsStream.cursor) {
      playlists.add(_loadPlaylist(playlistsStream, tracks: importedTracks));
    }
    return playlists;
  });

  if (wasPlayingPlaylist) {
    final playlist = playingPlaylistIdx! == 255
        ? importedPlaylist
        : playlists.elementAtOrNull(playingPlaylistIdx);
    if (playlist != null) {
      await audioPlayer.setPlaylist(playlist, index: playingIndex!);
    }
  }

  if (hasMainPlaylist) {
    mainPlaylist = playlists.elementAtOrNull(mainPlaylistIdx!);
  }

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
  final pageIndex = mainPageController.pageIndex;
  final shuffled = audioPlayer.shuffled;
  final looped = audioPlayer.looped;
  final wasPlayingPlaylist = audioPlayer.playlist != null;
  final playingPlaylistIdx = wasPlayingPlaylist
      ? audioPlayer.playlist! == importedPlaylist
            ? 255
            : playlists.indexOf(audioPlayer.playlist!)
      : null;
  final playingIndex = wasPlayingPlaylist ? audioPlayer.currentIndex! : null;
  final deviceName = audioPlayer.audioDevice.name;
  final position =
      audioPlayer.position.inMilliseconds / audioPlayer.duration.inMilliseconds;
  final hasMainPlaylist = mainPlaylist != null;

  stream.write(wPosX.toInt() + 32768, 16);
  stream.write(wPosY.toInt() + 32768, 16);
  stream.write((volume * 255).toInt(), 8);
  stream.write(pageIndex, 8);
  stream.writeBool(shuffled);
  stream.writeBool(looped);
  stream.writeBool(wasPlayingPlaylist);
  if (wasPlayingPlaylist) {
    stream.write(playingPlaylistIdx!, 8);
    stream.write(playingIndex!, 16);
  }
  stream.writeString(deviceName, 6);
  stream.write((position * 255).toInt(), 10);
  stream.writeBool(hasMainPlaylist);
  if (hasMainPlaylist) {
    stream.write(playlists.indexOf(mainPlaylist!), 8);
  }
  await file.writeAsBytes(stream.toBytes());

  final tracksFile = File('${dir.path}/Flux Player/tracks');
  await tracksFile.create(recursive: true);
  final tracksStream = BitStream();

  for (var track in importedPlaylist.tracks) {
    _saveTrack(tracksStream, track);
  }
  await tracksFile.writeAsBytes(tracksStream.toBytes());

  final playlistsFile = File('${dir.path}/Flux Player/playlists');
  await playlistsFile.create(recursive: true);
  final playlistsStream = BitStream();

  for (var playlist in playlists) {
    _savePlaylist(playlistsStream, playlist, tracks: importedPlaylist.tracks);
  }
  await playlistsFile.writeAsBytes(playlistsStream.toBytes());
}

AudioTrack _loadTrack(BitStream stream) {
  final path = stream.readString(8);
  return AudioTrack.fromPath(path);
}

void _saveTrack(BitStream stream, AudioTrack track) {
  stream.writeString(track.path, 8);
}

Playlist _loadPlaylist(BitStream stream, {required List<AudioTrack> tracks}) {
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
  required List<AudioTrack> tracks,
}) {
  stream.writeString(playlist.title, 6);
  stream.write(playlist.tracks.length, 16);
  playlist.tracks
      .map((e) => tracks.indexOf(e))
      .where((e) => e != -1)
      .forEach((e) => stream.write(e, 16));
}
