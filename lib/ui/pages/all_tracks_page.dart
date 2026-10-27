import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../../core/models/playlist.dart';
import '../../core/models/track.dart';
import '../../core/repositories/library_repository.dart';
import '../../core/repositories/playlist_repository.dart';
import '../../core/services/audio_player.dart';
import '../../core/utils/global_paint_bounds.dart';
import '../../core/utils/track_search.dart';
import '../widgets/search_field.dart';
import '../widgets/track_details.dart';
import '../widgets/track_list_view.dart';

enum _Sorting { title, artist, date }

class AllTracksPage extends StatefulWidget {
  const AllTracksPage({super.key});

  @override
  State<AllTracksPage> createState() => _AllTracksPageState();
}

class _AllTracksPageState extends State<AllTracksPage> {
  late final TrackListController controller = .new();

  var query = '';
  _Sorting sorting = .title;

  List<Playlist> get playlists => playlistRepository.getAllPlaylists();

  String sortingToText(_Sorting sorting) => switch (sorting) {
    .title => 'Название',
    .artist => 'Исполнитель',
    .date => 'Дата добавл.',
  };

  int _sort(Track a, Track b) => switch (sorting) {
    .title => a.title.compareTo(b.title),
    .artist => a.artist.compareTo(b.artist),
    .date =>
      a.isRemote
          ? 1
          : File(b.path)
                .lastModifiedSync()
                .compareTo(File(a.path).lastModifiedSync()),
  };

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() => this.query = query);
    if (query.isNotEmpty) {
      controller.jumpTo(0);
    }
  }

  Future<void> _onSortingChanged(_Sorting sort) async =>
      setState(() => sorting = sort);

  @override
  Widget build(BuildContext context) {
    if (libraryRepository.getPaths().isEmpty) {
      return Column(
        mainAxisAlignment: .center,
        spacing: 16,
        children: [
          const Text('У вас нет путей библиотек!'),
          TextButton(
            onPressed: () async {
              final path = await FilePicker.getDirectoryPath();
              if (path == null) return;

              setState(() => libraryRepository.addPath(path));
            },
            child: const Text('Выбрать путь'),
          ),
        ],
      );
    }

    return FutureBuilder(
      future: libraryRepository.getAllTracks(),
      builder: (context, asyncSnapshot) {
        if (!asyncSnapshot.hasData) return const SizedBox();

        final allTracks = asyncSnapshot.requireData;
        final tracks =
            query.isNotEmpty ? searchTracks(allTracks, query) : allTracks
              ..sort(_sort);

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchField(
                    hint: 'Поиск треков',
                    onChanged: _onQueryChanged,
                  ),
                ),
                AnimatedSize(
                  duration: Durations.short3,
                  child: query.isEmpty
                      ? Builder(
                          builder: (context) => TextButton.icon(
                            onPressed: () async {
                              final sort = await showContextMenu(
                                context,
                                contextMenu: ContextMenu<_Sorting>(
                                  entries: [
                                    MenuItem(
                                      label: Text(sortingToText(.title)),
                                      value: .title,
                                    ),
                                    MenuItem(
                                      label: Text(sortingToText(.artist)),
                                      value: .artist,
                                    ),
                                    MenuItem(
                                      label: Text(sortingToText(.date)),
                                      value: .date,
                                    ),
                                  ],
                                  position: context
                                      .findRenderObject()!
                                      .globalPaintBounds
                                      .bottomCenter,
                                ),
                              );
                              if (sort != null && sort != sorting) {
                                await _onSortingChanged(sort);
                              }
                            },
                            label: Text(sortingToText(sorting)),
                            icon: const Icon(Icons.sort_rounded),
                            style: .new(
                              foregroundColor: .all(
                                Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(width: 0),
                ),
              ],
            ),
            Expanded(
              child: TrackListView(
                tracks: tracks,
                controller: controller,
                showWatchTrack: query.isEmpty,
                menuEntriesBuilder: (context, index) {
                  final track = tracks[index];
                  return [
                    MenuItem(
                      label: const Text('Играть следующим'),
                      onSelected: (_) => audioPlayer.addNext(track),
                    ),
                    if (playlists.isNotEmpty &&
                        playlists.any((e) => !e.contains(track)))
                      MenuItem.submenu(
                        label: const Text('Добавить в плейлист'),
                        items: playlists
                            .where((e) => !e.contains(track))
                            .map(
                              (e) => MenuItem<void>(
                                label: Text(e.title),
                                onSelected: (_) => e.add(track),
                              ),
                            )
                            .toList(),
                      ),
                    if (playlists.isNotEmpty &&
                        playlists.any((e) => e.contains(track)))
                      MenuItem.submenu(
                        label: const Text('Удалить из плейлиста'),
                        items: playlists
                            .where((e) => e.contains(track))
                            .map(
                              (e) => MenuItem<void>(
                                label: Text(e.title),
                                onSelected: (_) => e.remove(track),
                              ),
                            )
                            .toList(),
                      ),
                    const MenuItem(label: Text('Удалить')), // TODO
                    MenuItem(
                      label: const Text('Свойства'),
                      onSelected: (_) => showDialog(
                        context: context,
                        builder: (context) => TrackDetails(track),
                      ),
                    ),
                  ];
                },
                onTrackPlayed: (index) => audioPlayer.setQueue(
                  tracks.toList(),
                  index: index,
                  play: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
