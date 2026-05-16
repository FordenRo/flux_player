import 'dart:async';

import '../config.dart';
import 'track.dart';

class Playlist {
  Playlist({required this.title, List<Track>? tracks}) : tracks = tracks ?? [];
  String title;
  List<Track> tracks;

  static Future<Playlist> fromJson(Map<String, dynamic> json) async => .new(
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
