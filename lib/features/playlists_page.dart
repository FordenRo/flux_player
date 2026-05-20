import 'package:flutter/material.dart';

import '../app/caption_widget.dart';
import '../core/audio_player/audio_player.dart';
import '../core/audio_player/playlist.dart';
import '../core/config.dart';
import '../core/constants.dart';
import '../widgets/playlist_tile.dart';
import 'track_list/track_list.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final CaptionButtonController buttonController = .new();
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
              colorScheme.primaryContainer.withAlpha(100),
              colorScheme.surface,
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
              itemBuilder: (context, idx) => PlaylistLabel(
                playlists[idx],
                onTap: () {
                  captionController.addIconButton(
                    builder: (context) => IconButton(
                      onPressed: () {
                        buttonController.remove();
                        setState(() => openedPlaylist = null);
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
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
          onTrackSelected: (idx) =>
              audioPlayer.setPlaylist(openedPlaylist!, index: idx, play: true),
          trackMenuItemsBuilder: (idx) => [
            .new(
              text: 'Удалить из плейлиста',
              onTap: () => openedPlaylist!.tracks.removeAt(idx),
            ),
          ],
        );
}
