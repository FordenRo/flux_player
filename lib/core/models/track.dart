import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    as audio_metadata;
import '../audio_player/audio_player.dart';

class Track {
  Track._({required this.path, required this.metadata, required this.created});
  final String path;
  final AudioMetadata metadata;
  final DateTime created;

  String get id => '$title / $author';
  String get title => metadata.title ?? 'Unnamed';
  String get author => metadata.artist ?? 'No artist';
  Duration get duration => metadata.duration ?? Duration.zero;
  Picture? get picture => metadata.pictures.firstOrNull;

  static Track fromFile(File file) {
    final metadata = audio_metadata.readMetadata(file, getImage: true);

    return ._(
      path: file.path,
      metadata: metadata,
      created: file.statSync().changed,
    );
  }
}
