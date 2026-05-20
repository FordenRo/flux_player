import 'package:flutter/material.dart';

import '../core/audio_player/audio_player.dart';
import '../core/services/config_service.dart';
import '../widgets/track_list/track_list.dart';

class AllTracksPage extends StatefulWidget {
  const AllTracksPage({super.key});

  @override
  State<AllTracksPage> createState() => _AllTracksPageState();
}

class _AllTracksPageState extends State<AllTracksPage> {
  @override
  Widget build(BuildContext context) => TrackList(
    importedPlaylist.tracks,
    onTrackSelected: (idx) =>
        audioPlayer.setPlaylist(importedPlaylist, index: idx, play: true),
    trackMenuItemsBuilder: (idx) => [
      .new(
        text: 'Удалить песню',
        onTap: () => importedPlaylist.tracks.removeAt(idx),
      ),
    ],
  );
}
