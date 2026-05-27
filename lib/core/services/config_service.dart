import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/app_controller.dart';
import '../audio_player/audio_player.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../theme/theme.dart';
import '../utils/bitstream.dart';

const audioExtensions = ['mp3', 'ogg', 'aac', 'flac', 'midi', 'wav', 'v4a'];

final configService = ConfigService._();

Playlist importedPlaylist = .new(title: 'Imported');
Playlist? mainPlaylist;
List<Playlist> playlists = [];

class ConfigService {
  ConfigService._();

  final List<String> _addedFiles = [];
  final List<String> _addedFolders = [];
  final List<StreamSubscription<FileSystemEvent>> _watchingFolders = [];

  List<String> get addedFiles => _addedFiles;
  List<String> get addedFolders => _addedFolders;

  Future<void> removeFile(String path) async {
    _addedFiles.remove(path);
    importedPlaylist.removeWhere((e) => e.path == path);
  }

  Future<void> removeFolder(String path) async {
    _addedFolders.remove(path);
    importedPlaylist.removeWhere((e) => File(e.path).parent.path == path);
  }

  Future<void> addFile(String path) async {
    if (_addedFiles.contains(path)) return;

    final file = File(path);
    if (!file.existsSync()) return;

    final track = Track.fromFile(file);
    if (_isAlreadyImported(track)) return;

    _addedFiles.add(path);
    importedPlaylist.add(track);
  }

  Future<void> addFolder(String path) async {
    if (_addedFolders.contains(path)) return;

    final dir = Directory(path);
    if (!dir.existsSync()) return;

    await for (final file in dir.list().where(
      (e) => audioExtensions.contains(e.path.split('.').last),
    )) {
      if (file is! File) continue;

      final track = Track.fromFile(file);
      if (_isAlreadyImported(track)) continue;

      importedPlaylist.add(track);
    }
    _addedFolders.add(path);
    _watchingFolders.add(dir.watch().listen(_onFolderEvent));
  }

  void _onFolderEvent(FileSystemEvent event) {
    switch (event) {
      case FileSystemCreateEvent(path: final path, isDirectory: false):
        final track = Track.fromFile(File(path));
        if (_isAlreadyImported(track)) return;

        importedPlaylist.add(track);
      case FileSystemDeleteEvent(path: final path):
        importedPlaylist.removeWhere((e) => e.path == path);
      default:
        return;
    }
  }

  bool _isAlreadyImported(Track track) =>
      importedPlaylist.where((e) => e.id == track.id).isNotEmpty;

  Future<void> loadConfiguration() async {
    final path =
        '${(await getApplicationDocumentsDirectory()).path}/Flux Player';

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

    await _loadPaths(path);
    await _loadPlaylists(
      path,
      playingPlaylistIdx: playingPlaylistIdx,
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

  Future<void> _loadPaths(String path) async {
    final file = File('$path/paths.txt');
    if (!file.existsSync()) return;

    for (final path in await file.readAsLines()) {
      if (FileSystemEntity.isDirectorySync(path)) {
        await addFolder(path);
      } else if (FileSystemEntity.isFileSync(path)) {
        await addFile(path);
      }
    }
  }

  Future<void> _loadPlaylists(
    String path, {
    required bool hasMainPlaylist,
    int? mainPlaylistIdx,
    int? playingPlaylistIdx,
  }) async {
    final dir = Directory('$path/playlists');
    if (!dir.existsSync()) return;

    playlists = await (await dir.list().map((file) {
      if (file is! File) return null;
      return _loadPlaylist(file, importedTracks: importedPlaylist.toList());
    }).toList()).nonNulls.wait;

    if (playingPlaylistIdx != null) {
      final playlist = playingPlaylistIdx == 255
          ? importedPlaylist
          : playlists.elementAtOrNull(playingPlaylistIdx);
      if (playlist != null) {
        await audioPlayer.setPlaylist(playlist);
      }
    }

    if (hasMainPlaylist) {
      mainPlaylist = playlists.elementAtOrNull(mainPlaylistIdx!);
    }
  }

  Future<Playlist> _loadPlaylist(
    File file, {
    required List<Track> importedTracks,
  }) async => Playlist(
    title: file.uri.pathSegments.last.split('.').first,
    tracks: (await file.readAsLines())
        .map((e) => importedTracks.where((track) => track.id == e).firstOrNull)
        .nonNulls
        .toList(),
  );

  Future<void> _loadQueue(String path, {int? playingIndex}) async {
    final file = File('$path/queue.txt');
    if (!file.existsSync()) return;

    await audioPlayer.setQueue(
      (await file.readAsLines())
          .map(
            (e) => importedPlaylist.where((track) => track.id == e).firstOrNull,
          )
          .nonNulls
          .toList(),
      index: playingIndex,
    );
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
    final path =
        '${(await getApplicationDocumentsDirectory()).path}/Flux Player';

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
    if (hasMainPlaylist) stream.write(playlists.indexOf(mainPlaylist!), 8);
    stream.write(seedColors.indexOf(appTheme.seedColor), 5);
    await file.writeAsBytes(stream.toBytes());

    await _savePaths(path);
    await _savePlaylists(path);
    await _saveQueue(path);
  }

  Future<void> _savePaths(String path) async {
    final file = File('$path/paths.txt');
    await file.create(recursive: true);
    await file.writeAsString((_addedFolders + _addedFiles).join('\n'));
  }

  Future<void> _savePlaylists(String path) =>
      Future.wait(playlists.map((e) => _savePlaylist('$path/playlists', e)));

  Future<void> _savePlaylist(String path, Playlist playlist) async {
    final file = File('$path/${playlist.title}.txt');
    await file.create(recursive: true);
    await file.writeAsString(playlist.map((e) => e.id).join('\n'));
  }

  Future<void> _saveQueue(String path) async {
    final file = File('$path/queue.txt');
    await file.create(recursive: true);
    await file.writeAsString(audioPlayer.queue.map((e) => e.id).join('\n'));
  }
}
