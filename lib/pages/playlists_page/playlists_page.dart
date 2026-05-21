import 'package:flutter/material.dart';

import '../../app/caption_widget/caption_widget.dart';
import '../../core/audio_player/audio_player.dart';
import '../../core/models/playlist.dart';
import '../../core/services/config_service.dart';
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
            builder: (context, asyncSnapshot) => ListView.builder(
              itemCount: playlists.length,
              itemExtent: 110,
              itemBuilder: (context, idx) => PlaylistTile(
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
              ),
            ),
          ),
        )
      : TrackList(
          openedPlaylist!.tracks,
          selectionController: selectionController,
          onTrackSelected: (idx) =>
              audioPlayer.setPlaylist(openedPlaylist!, index: idx, play: true),
          trackMenuItemsBuilder: (idx) => [
            .new(
              text: 'Удалить из плейлиста',
              onTap: () =>
                  selectionController.hasSelection(openedPlaylist!.tracks[idx])
                  ? selectionController.selectedTracks.forEach(
                      openedPlaylist!.tracks.remove,
                    )
                  : openedPlaylist!.tracks.removeAt(idx),
            ),
          ],
        );
}
