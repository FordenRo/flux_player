import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../services/config_service.dart';
import '../utils/move_element.dart';
import 'track.dart';

class Playlist with ChangeNotifier, Iterable<Track> {
  Playlist({required this.title, List<Track>? tracks}) : _tracks = tracks ?? [];

  String title;
  final List<Track> _tracks;

  void add(Track track) {
    _tracks.add(track);
    notifyListeners();
  }

  void addAll(Iterable<Track> iterable) {
    _tracks.addAll(iterable);
    notifyListeners();
  }

  bool remove(Track value) {
    final result = _tracks.remove(value);
    notifyListeners();
    return result;
  }

  void removeWhere(bool Function(Track) test) {
    _tracks.removeWhere(test);
    notifyListeners();
  }

  void removeAt(int index) {
    _tracks.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _tracks.clear();
    notifyListeners();
  }

  void move(int index, int newIndex) {
    _tracks.move(index, newIndex);
    notifyListeners();
  }

  List<Track> asList() => _tracks;

  static Future<Playlist> fromJson(Map<String, dynamic> json) async => .new(
    title: json['title'] as String,
    tracks: (json['tracks'] as List?)
        ?.cast<int>()
        .map((idx) => importedPlaylist.elementAtOrNull(idx))
        .nonNulls
        .toList(),
  );

  dynamic toJson() => {'title': title, 'tracks': map((e) => e.path).toList()};

  @override
  Iterator<Track> get iterator => _tracks.iterator;

  Track operator [](int other) => _tracks[other];
}
