import 'package:flutter/material.dart';

import '../core/audio_player/audio_player.dart';
import '../core/services/config_service.dart';
import '../widgets/track_list/track_list.dart';
import '../widgets/track_list/widgets/track_item/track_selection_controller.dart';

class AllTracksPage extends StatefulWidget {
  const AllTracksPage({super.key});

  @override
  State<AllTracksPage> createState() => _AllTracksPageState();
}

class _AllTracksPageState extends State<AllTracksPage> {
  final TrackSelectionController selectionController = .new();

  @override
  Widget build(BuildContext context) => TrackList(
    importedPlaylist.tracks,
    selectionController: selectionController,
    onTrackSelected: (idx) =>
        audioPlayer.setPlaylist(importedPlaylist, index: idx, play: true),
    trackMenuItemsBuilder: (idx) => [
      .new(
        text: selectionController.hasSelection(importedPlaylist.tracks[idx])
            ? 'Удалить песни'
            : 'Удалить песню',
        onTap: () =>
            selectionController.hasSelection(importedPlaylist.tracks[idx])
            ? selectionController.selectedTracks.forEach(
                importedPlaylist.tracks.remove,
              )
            : importedPlaylist.tracks.removeAt(idx),
      ),
    ],
  );
}
