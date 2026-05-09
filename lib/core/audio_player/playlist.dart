import 'dart:async';
import 'track.dart';
import '../config.dart';

class Playlist {
  String title;
  List<Track> tracks;

  Playlist({required this.title, List<Track>? tracks}) : tracks = tracks ?? [];

  static Future<Playlist> fromJson(dynamic json) async => .new(
    title: json['title'] as String,
    tracks: (json['tracks'] as List?)
        ?.cast<int>()
        .map((idx) => importedPlaylist.tracks.elementAtOrNull(idx))
        .nonNulls
        .toList(),
  );

  dynamic toJson() => {
    'title': title,
    'tracks': tracks.map((e) => e.path).toList(),
  };
}
