import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'audio_player.dart';

Future<void> loadConfiguration() async {
  var dir = await getApplicationDocumentsDirectory();
  var file = File('${dir.path}/Flux Player/config.json');
  if (!await file.exists()) {
    return;
  }
  var json = jsonDecode(await file.readAsString());

  List<double>? wPos = json['wPos'];
  if (wPos != null) {
    await windowManager.setPosition(Offset(wPos[0], wPos[1]));
  }

  importedTracks = await Future.wait(
    (json['imported'] as List?)?.cast<String>().map(AudioTrack.fromPath) ?? [],
  );

  var queue =
      (json['queue'] as List?)
          ?.cast<String>()
          .map(
            (path) =>
                importedTracks.where((track) => track.path == path).firstOrNull,
          )
          .nonNulls
          .toList() ??
      [];
  if (queue.isNotEmpty) {
    await audioPlayer.setQueue(queue, index: json['index'] as int? ?? 0);
  }

  await audioPlayer.setVolume(json['volume'] ?? 1);
  audioPlayer.setLooped(json['lp'] as bool? ?? false);
  audioPlayer.setShuffled(json['sh'] as bool? ?? false);

  await Future.microtask(() async {
    await audioPlayer.setAudioDevice(
      audioPlayer.audioDevices.firstWhere(
        (e) => e.name == json['device'] as String?,
        orElse: () => audioPlayer.audioDevice,
      ),
    );
  });

  Future.delayed(const Duration(milliseconds: 100), () {
    if (queue.isNotEmpty) {
      return audioPlayer.seek(Duration(milliseconds: json['pos'] as int? ?? 0));
    }
  });
}

Future<void> saveConfiguration() async {
  var dir = await getApplicationDocumentsDirectory();
  var file = File('${dir.path}/Flux Player/config.json');
  var wPos = await windowManager.getPosition();
  await file.create(recursive: true);
  await file.writeAsString(
    jsonEncode({
      'device': audioPlayer.audioDevice.name,
      'volume': audioPlayer.volume,
      'imported': importedTracks.map((e) => e.path).toList(),
      'queue': audioPlayer.queue.map((e) => e.path).toList(),
      'index': audioPlayer.currentIndex,
      'pos': audioPlayer.position.inMilliseconds,
      'wPos': [wPos.dx, wPos.dy],
      'lp': audioPlayer.looped,
      'sh': audioPlayer.shuffled,
    }),
  );
}
