import 'package:flutter/material.dart';

import '../audio_player.dart';
import '../config.dart';
import '../widgets/playlist_label.dart';
import '../widgets/track_list.dart';
import 'main_page.dart';

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
            shape: CircleBorder(),
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
      : TrackList(playlist: openedPlaylist!);
}
