import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show readMetadata;

import '../models/track.dart';

const audioExtensions = ['mp3', 'ogg', 'aac', 'flac', 'midi', 'wav', 'v4a'];

final libraryRepository = LibraryRepository._();

class LibraryRepository {
  LibraryRepository._();

  final List<Track> _cachedTracks = [];
  List<Track>? _allTracks;
  var _paths = <String>{};
  final _subscriptions = <StreamSubscription<FileSystemEvent>>[];

  Future<List<Track>> getAllTracks() async => _allTracks ??= await _paths
      .map(
        (e) =>
            Directory(e)
                .listSync()
                .whereType<File>()
                .where((e) => audioExtensions.contains(e.path.split('.').last))
                .map(getTrackFromFile),
      )
      .fold(<Future<Track>>[], (a, b) => a.followedBy(b).toList())
      .wait;

  List<String> getPaths() => _paths.toList();

  Future<Track> getTrackFromFile(File file) async {
    var track = _cachedTracks.where((e) => e.path == file.path).firstOrNull;
    if (track == null) {
      track = await _loadTrack(file);
      _cachedTracks.add(track);
    }
    return track;
  }

  void setPaths(Iterable<String> paths) => _paths = paths.toSet();

  void addPath(String path) {
    if (_paths.contains(path)) return;

    _paths.add(path);
    _subscriptions.add(Directory(path).watch().listen(_fileEvent));
    _allTracks = null;
  }

  void _fileEvent(FileSystemEvent event) {
    if (event.isDirectory) return;
    switch (event) {
      case FileSystemCreateEvent():
        _allTracks = null;
      case FileSystemDeleteEvent(:final path):
        _allTracks = null;
        _cachedTracks.removeWhere((e) => e.path == path);
      default:
        return;
    }
  }

  void removePath(String path) {
    _paths.remove(path);
    _cachedTracks.removeWhere((e) => e.path == path);
    _allTracks = null;
  }
}

Future<Track> _loadTrack(File file) async {
  final metadata = await Isolate.run(() => readMetadata(file, getImage: true));

  return .new(
    title: metadata.title ?? file.uri.pathSegments.last,
    artist: metadata.artist ?? 'No artist',
    path: file.path,
    duration: metadata.duration!,
    album: metadata.album,
    picture: metadata.pictures.elementAtOrNull(0)?.bytes,
  );
}
