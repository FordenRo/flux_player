import 'dart:async';
import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    as audio_metadata;
import '../audio_player/audio_player.dart';

class Track {
  Track._({required this.path, required this.metadata, required this.created});
  final String path;
  final AudioMetadata metadata;
  final DateTime created;

  String get title => metadata.title ?? 'Unnamed';
  String get author => metadata.artist ?? 'No artist';
  Duration get duration => metadata.duration ?? Duration.zero;
  Picture? get picture => metadata.pictures.firstOrNull;

  static Future<Track> fromJson(dynamic json) async {
    final path = (json as Map<String, dynamic>)['path'] as String;
    final file = File(path);
    final metadata = audio_metadata.readMetadata(file, getImage: true);

    return ._(path: path, metadata: metadata, created: file.statSync().changed);
  }

  static Track fromPath(String path) {
    final file = File(path);
    final metadata = audio_metadata.readMetadata(file, getImage: true);

    return ._(path: path, metadata: metadata, created: file.statSync().changed);
  }

  dynamic toJson() => {'path': path};
}
