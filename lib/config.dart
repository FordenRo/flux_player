import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'music_controller.dart';

Future<void> loadConfiguration() async {
  var dir = await getApplicationDocumentsDirectory();
  var file = File('${dir.path}/config.json');
  if (!await file.exists()) {
    return;
  }
  var json = jsonDecode(await file.readAsString());

  importedTracks = await Future.wait(
    (json['imported'] as List).cast<String>().map(AudioTrack.fromPath),
  );
  await audioPlayer.setVolume(json['volume']);
  await Future.microtask(
    () => audioPlayer.setAudioDevice(
      audioPlayer.audioDevices.firstWhere(
        (e) => e.name == json['device'] as String,
        orElse: () => audioPlayer.audioDevice,
      ),
    ),
  );
}

Future<void> saveConfiguration() async {
  var dir = await getApplicationDocumentsDirectory();
  var file = File('${dir.path}/config.json');
  await file.create(recursive: true);
  await file.writeAsString(
    jsonEncode({
      'device': audioPlayer.audioDevice.name,
      'volume': audioPlayer.volume,
      'imported': importedTracks.map((e) => e.path).toList(),
    }),
  );
}
