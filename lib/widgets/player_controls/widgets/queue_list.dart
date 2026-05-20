import 'package:flutter/material.dart';

import '../../../core/audio_player/audio_player.dart';
import '../../../core/constants.dart';
import '../../track_list/track_list.dart';

class QueueList extends StatelessWidget {
  const QueueList({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: .bottomRight,
    child: Padding(
      padding: const .only(bottom: 80, right: 20, left: 60, top: 60),
      child: SizedBox(
        width: 500,
        height: 400,
        child: Card(
          color: colorScheme.surface,
          child: Padding(
            padding: const .all(12),
            child: TrackList(
              audioPlayer.queue,
              onTrackSelected: audioPlayer.setIndex,
              sortEnabled: false,
              trackMenuItemsBuilder: (idx) => [
                .new(
                  text: 'Убрать',
                  onTap: () => audioPlayer.queue.removeAt(idx),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
