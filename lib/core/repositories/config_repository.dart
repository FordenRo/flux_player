import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:window_manager/window_manager.dart';

import '../models/app_config.dart';
import '../services/audio_player.dart';
import '../services/network_service.dart';
import 'library_repository.dart';
import 'playlist_repository.dart';

final configRepository = ConfigRepository._();

class ConfigRepository {
  ConfigRepository._();

  late ConfigStream stream = .new(page: _pageController.stream.distinct());

  var _page = 0;

  int get page => _page;
  set page(int value) {
    _page = value;
    _pageController.add(value);
  }

  final StreamController<int> _pageController = .broadcast();

  Future<void> apply(AppConfig config) async {
    if (config.page != null) page = config.page!;
    if (config.windowPosition != null) {
      await windowManager.setPosition(
        Offset(
          config.windowPosition!.x.toDouble(),
          config.windowPosition!.y.toDouble(),
        ),
      );
    }
    if (config.windowSize != null) {
      await windowManager.setSize(
        Size(config.windowSize!.x.toDouble(), config.windowSize!.y.toDouble()),
      );
    }
    if (config.libraryPaths != null) {
      libraryRepository.setPaths(config.libraryPaths!);
    }
    if (config.downloadPath != null) {
      networkService.downloadPath = config.downloadPath;
    }
    final device = config.device != null
        ? audioPlayer.audioDevices
              .where((e) => e.name == config.device)
              .firstOrNull
        : null;
    if (device != null) await audioPlayer.setAudioDevice(device);
    if (config.volume != null) await audioPlayer.setVolume(config.volume!);
    await playlistRepository.loadPlaylists();
    if (config.playlist != null) {
      final playlist = playlistRepository
          .getAllPlaylists()
          .where((e) => e.title == config.playlist!)
          .firstOrNull;
      await audioPlayer.setPlaylist(playlist!);
    }
    if (config.queue != null) {
      final queue = await config.queue!
          .where((e) => File(e).existsSync())
          .map((e) => libraryRepository.getTrackFromFile(File(e)))
          .wait;
      await audioPlayer.setQueue(queue, index: config.index);
    }
    if (config.looped != null) audioPlayer.setLooped(config.looped!);
    if (config.shuffled != null) {
      audioPlayer.setShuffled(config.shuffled!);
    }
    if (config.position != null) {
      await Future.microtask(
        () => audioPlayer.seek(Duration(seconds: config.position!)),
      );
    }
  }

  Future<AppConfig> getConfig() async {
    final Size(width: ww, height: wh) = await windowManager.getSize();
    final Offset(dx: wx, dy: wy) = await windowManager.getPosition();
    return .new(
      index: audioPlayer.currentIndex,
      page: page,
      windowPosition: Point(wx.toInt(), wy.toInt()),
      windowSize: Point(ww.toInt(), wh.toInt()),
      libraryPaths: libraryRepository.getPaths(),
      device: audioPlayer.audioDevice.name,
      volume: audioPlayer.volume,
      shuffled: audioPlayer.isShuffled,
      looped: audioPlayer.isLooped,
      queue: audioPlayer.queue.map((e) => e.path).toList(),
      position: audioPlayer.position.inSeconds,
      downloadPath: networkService.downloadPath,
      playlist: audioPlayer.currentPlaylist?.title,
    );
  }

  Future<void> dispose() => Future.wait([_pageController.close()]);
}

class ConfigStream {
  new({required this.page});

  final Stream<int> page;
}
