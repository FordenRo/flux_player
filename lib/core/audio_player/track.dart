import 'dart:async';
import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    as audio_metadata;
import 'audio_player.dart';

class Track {
  Track._internal({required this.path, required this.metadata});
  final String path;
  final AudioMetadata metadata;

  String get title => metadata.title ?? 'Unnamed';
  String get author => metadata.artist ?? 'No artist';
  Duration get duration => metadata.duration ?? Duration.zero;
  Picture? get picture => metadata.pictures.firstOrNull;

  static Future<Track> fromJson(dynamic json) async {
    final path = (json as Map<String, dynamic>)['path'] as String;
    final metadata = audio_metadata.readMetadata(.new(path), getImage: true);

    return ._internal(path: path, metadata: metadata);
  }

  static Track fromPath(String path) {
    final metadata = audio_metadata.readMetadata(.new(path), getImage: true);

    return ._internal(path: path, metadata: metadata);
  }

  dynamic toJson() => {'path': path};
}
