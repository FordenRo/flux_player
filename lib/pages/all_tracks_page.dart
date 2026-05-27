import 'package:flutter/material.dart';

import '../core/audio_player/audio_player.dart';
import '../core/services/config_service.dart';
import '../core/utils/move_element.dart';
import '../widgets/simple_menu.dart';
import '../widgets/track_list/track_list.dart';
import '../widgets/track_list/widgets/track_item/track_selection_controller.dart';

class AllTracksPage extends StatefulWidget {
  const AllTracksPage({super.key});

  @override
  State<AllTracksPage> createState() => _AllTracksPageState();
}

class _AllTracksPageState extends State<AllTracksPage> {
  final TrackSelectionController selectionController = .new();

  void _onTrackSelected(int idx) =>
      audioPlayer.setPlaylist(importedPlaylist, index: idx, play: true);

  void _onTrackMoved(int oldIndex, int newIndex) =>
      setState(() => importedPlaylist.move(oldIndex, newIndex));

  List<SimpleMenuItem<dynamic>> _menuItemsBuilder(int idx) => [
    .new(
      text: selectionController.hasSelection(importedPlaylist[idx])
          ? 'Удалить песни'
          : 'Удалить песню',
      onTap: () => selectionController.hasSelection(importedPlaylist[idx])
          ? selectionController.selectedTracks.forEach(importedPlaylist.remove)
          : importedPlaylist.removeAt(idx),
    ),
  ];

  @override
  Widget build(BuildContext context) => TrackList(
    importedPlaylist.toList(),
    customSortEnabled: false,
    selectionController: selectionController,
    onTrackSelected: _onTrackSelected,
    onTrackMoved: _onTrackMoved,
    trackMenuItemsBuilder: _menuItemsBuilder,
  );
}
