import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/playlist.dart';
import '../repositories/library_repository.dart';

final playlistService = PlaylistService._();

class PlaylistService {
  PlaylistService._();

  Future<void> savePlaylists(List<Playlist> playlists) async {
    final dir = '${(await getApplicationSupportDirectory()).path}/playlists';

    for (final e in playlists) {
      File('$dir/${e.title}.m3u')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '#EXTM3U\n'
          '${e.map((e) => e.path).join('\n')}',
        );
    }
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    final dir = '${(await getApplicationSupportDirectory()).path}/playlists';
    File('$dir/${playlist.title}.m3u').deleteSync();
  }

  Future<List<Playlist>> loadPlaylists() async {
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/playlists',
    );
    if (!dir.existsSync()) return [];

    return dir
        .listSync()
        .whereType<File>()
        .where((e) => e.uri.pathSegments.last.endsWith('m3u'))
        .map(
          (e) async => Playlist(
            title: e.uri.pathSegments.last.split('.').first,
            tracks: await (await e.readAsLines())
                .where((l) => !l.startsWith('#'))
                .map((l) => libraryRepository.getTrackFromFile(File(l)))
                .wait,
          ),
        )
        .wait;
  }
}
