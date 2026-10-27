import 'dart:convert' show jsonDecode;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../repositories/library_repository.dart';

final networkService = NetworkService._();

class NetworkService {
  NetworkService._();

  String? downloadPath;

  final client = http.Client();

  Future<List<Track>> queryTracks(String query) async =>
      parse(
        (await client.get(Uri.https('ru.hitmoz.org', '/search', {'q': query})))
            .body,
      ).getElementsByClassName('tracks__list').firstOrNull?.children.map((e) {
        final meta =
            jsonDecode(e.attributes['data-musmeta']!) as Map<String, dynamic>;
        final [minutes, seconds] = e
            .getElementsByClassName('track__fulltime')
            .first
            .text
            .split(':')
            .map(int.parse)
            .toList();
        final duration = Duration(minutes: minutes, seconds: seconds);
        final path = e
            .getElementsByClassName('track__download-btn')
            .first
            .attributes['href'];

        return Track(
          path: Uri.https('ru.hitmoz.org', path!).toString(),
          title: meta['title'] as String,
          artist: meta['artist'] as String,
          duration: duration,
          isLocal: false,
        );
      }).toList() ??
      [];

  Future<TrackDownloadResult?> downloadTrack(Track track) async {
    final data = await client.readBytes(Uri.parse(track.path));
    final filename = '${track.artist} - ${track.title}.mp3';
    final downloadPath =
        this.downloadPath ?? await FilePicker.getDirectoryPath();
    if (downloadPath == null) return null;
    final file = File(downloadPath + Platform.pathSeparator + filename)
      ..writeAsBytesSync(data);
    return TrackDownloadResult(
      track: await libraryRepository.getTrackFromFile(file),
      file: file,
    );
  }
}

class TrackDownloadResult {
  const new({required this.track, required this.file});

  final Track track;
  final File file;
}
