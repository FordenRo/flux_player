import 'package:flutter/material.dart';

import '../../app/caption_widget/caption_widget.dart';
import '../../core/audio_player/audio_player.dart';
import '../../core/models/playlist.dart';
import '../../core/services/config_service.dart';
import '../../core/utils/move_element.dart';
import '../../widgets/simple_menu.dart';
import '../../widgets/track_list/track_list.dart';
import '../../widgets/track_list/widgets/track_item/track_selection_controller.dart';
import 'widgets/playlist_tile.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final CaptionWidgetController buttonController = .new();
  final TrackSelectionController selectionController = .new();
  Playlist? openedPlaylist;

  @override
  void dispose() {
    buttonController.dispose();
    super.dispose();
  }

  void _onTrackSelected(int idx) =>
      audioPlayer.setPlaylist(openedPlaylist!, index: idx, play: true);

  void _onPlaylistMoved(int oldIndex, int newIndex) =>
      setState(() => playlists.move(oldIndex, newIndex));

  List<SimpleMenuItem<dynamic>> _menuItemsBuilder(int idx) => [
    .new(
      text: 'Удалить из плейлиста',
      onTap: () => selectionController.hasSelection(openedPlaylist![idx])
          ? selectionController.selectedTracks.forEach(openedPlaylist!.remove)
          : openedPlaylist!.removeAt(idx),
    ),
  ];

  ReorderableListView _buildPlaylistList() => ReorderableListView.builder(
    itemCount: playlists.length,
    itemExtent: 110,
    buildDefaultDragHandles: false,
    onReorderItem: (oldIndex, newIndex) {
      if (newIndex > oldIndex) newIndex -= 1;
      _onPlaylistMoved(oldIndex, newIndex);
    },
    itemBuilder: (context, idx) => ReorderableDragStartListener(
      key: Key(idx.toString()),
      index: idx,
      child: _playlistBuilder(idx),
    ),
  );

  Widget _playlistBuilder(int idx) => PlaylistTile(
    playlists[idx],
    onTap: () {
      captionController.addWidget(
        builder: (context) => Row(
          spacing: 8,
          children: [
            IconButton(
              onPressed: () {
                buttonController.remove();
                setState(() => openedPlaylist = null);
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Text(openedPlaylist!.title),
          ],
        ),
        controller: buttonController,
      );
      setState(() => openedPlaylist = playlists[idx]);
    },
  );

  @override
  Widget build(BuildContext context) => openedPlaylist == null
      ? Scaffold(
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => playlists.add(.new(title: 'Новый плейлист')),
            shape: const CircleBorder(),
            backgroundColor: .alphaBlend(
              Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
              Theme.of(context).colorScheme.surface,
            ),
            child: const Icon(Icons.add),
          ),
          body: StreamBuilder(
            stream: Stream.periodic(
              const Duration(seconds: 1),
              (_) => playlists.length,
            ).distinct(),
            builder: (context, asyncSnapshot) => _buildPlaylistList(),
          ),
        )
      : ListenableBuilder(
          listenable: openedPlaylist!,
          builder: (context, child) => TrackList(
            openedPlaylist!.toList(),
            selectionController: selectionController,
            onTrackSelected: _onTrackSelected,
            onTrackMoved: openedPlaylist!.move,
            trackMenuItemsBuilder: _menuItemsBuilder,
          ),
        );
}
