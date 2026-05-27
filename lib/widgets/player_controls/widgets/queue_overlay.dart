import 'package:flutter/material.dart';

import '../../../core/audio_player/audio_player.dart';
import '../../../core/models/track.dart';
import '../../../core/utils/move_element.dart';
import '../../simple_menu.dart';
import '../../track_list/track_list_controller.dart';
import '../../track_list/widgets/floating_actions_overlay.dart';
import '../../track_list/widgets/track_item/track_item.dart';

class QueueOverlay extends StatefulWidget {
  const QueueOverlay({super.key});

  @override
  State<QueueOverlay> createState() => _QueueOverlayState();
}

class _QueueOverlayState extends State<QueueOverlay> {
  final TrackListController controller = .new(useIndex: true);

  List<Track> get queue => audioPlayer.queue;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _updatePlaybackIndex(int index) =>
      audioPlayer.setIndex(index, play: audioPlayer.isPlaying, load: false);

  void _onMove(int oldIndex, int newIndex) => setState(() {
    queue.move(oldIndex, newIndex);
    if (oldIndex == audioPlayer.currentIndex) {
      _updatePlaybackIndex(newIndex);
    } else if (oldIndex < audioPlayer.currentIndex! &&
        newIndex >= audioPlayer.currentIndex!) {
      _updatePlaybackIndex(audioPlayer.currentIndex! - 1);
    } else if (oldIndex > audioPlayer.currentIndex! &&
        newIndex <= audioPlayer.currentIndex!) {
      _updatePlaybackIndex(audioPlayer.currentIndex! + 1);
    }
  });

  void _onRemove(int index) => setState(() {
    queue.removeAt(index);
    if (index == audioPlayer.currentIndex) {
      audioPlayer.setIndex(index, play: audioPlayer.isPlaying);
    } else if (index < audioPlayer.currentIndex!) {
      _updatePlaybackIndex(audioPlayer.currentIndex! - 1);
    }
  });

  void _clearQueue() {
    Navigator.pop(context);
    audioPlayer.stop().then((_) => audioPlayer.setQueue([]));
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: .bottomRight,
    child: Padding(
      padding: const .only(bottom: 80, right: 20, left: 60, top: 60),
      child: SizedBox(
        width: 500,
        height: 400,
        child: Scaffold(
          floatingActionButton: FloatingActionsOverlay(
            listController: controller,
            tracks: queue,
          ),
          body: Card(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const .all(12),
              child: ReorderableListView.builder(
                itemCount: queue.length,
                itemExtent: 50,
                buildDefaultDragHandles: false,
                scrollController: controller,
                onReorderItem: _onMove,
                itemBuilder: (context, idx) => ReorderableDragStartListener(
                  key: Key(idx.toString()),
                  index: idx,
                  child: TrackItem(
                    queue[idx],
                    onPlay: () => audioPlayer.setIndex(idx),
                    showPlayNext: false,
                    removeCallback: () => _onRemove(idx),
                    menuItems: [
                      SimpleMenuItem(
                        text: 'Убрать',
                        onTap: () => _onRemove(idx),
                      ),
                      SimpleMenuItem(
                        text: 'Очистить список',
                        onTap: _clearQueue,
                      ),
                    ],
                    isSelectedCallback: () => audioPlayer.currentIndex == idx,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
