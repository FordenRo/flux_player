import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';

import '../music_controller.dart';

class TrackLabel extends StatefulWidget {
  const TrackLabel(this.playlist, this.index, {super.key});

  final List<AudioTrack> playlist;
  final int index;

  @override
  State<TrackLabel> createState() => _TrackLabelState();
}

class _TrackLabelState extends State<TrackLabel> {
  late var isSelected = audioPlayer.currentTrack == track;
  late var isPlaying = isSelected && audioPlayer.isPlaying;
  late final List<StreamSubscription> subscriptions;

  int get index => widget.index;
  List<AudioTrack> get playlist => widget.playlist;
  AudioTrack get track => playlist[index];

  @override
  void initState() {
    super.initState();

    subscriptions = [
      audioPlayer.stream.isPlaying.listen((_) => update()),
      audioPlayer.stream.currentTrack.listen((_) => update()),
    ];
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await Future.wait(subscriptions.map((e) => e.cancel()));
  }

  void update() {
    final selected = audioPlayer.currentTrack == track;
    final playing = selected && audioPlayer.isPlaying;

    if (selected != isSelected || playing != isPlaying) {
      setState(() {
        isPlaying = playing;
        isSelected = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: .opaque,
    onSecondaryTapDown: (e) => showMenu(context, e),
    child: Card(
      clipBehavior: .hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary)
            : .none,
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 8),
        child: Row(
          spacing: 8,
          children: [
            IconButton(
              onPressed: () async {
                if (isSelected) {
                  if (isPlaying) {
                    await audioPlayer.pause();
                  } else {
                    await audioPlayer.play();
                  }
                } else {
                  if (audioPlayer.queue != playlist) {
                    await audioPlayer.setQueue(
                      playlist,
                      index: index,
                      play: true,
                    );
                  } else {
                    await audioPlayer.jump(index);
                  }
                }
              },
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              style: ButtonStyle(
                minimumSize: .all(Size.zero),
                iconSize: .all(24),
                padding: .all(.all(4)),
              ),
            ),
            Text(track.title),
            Text(
              track.author,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.inverseSurface.withAlpha(170),
              ),
            ),
            const Expanded(child: SizedBox()),
            Text(
              '${track.duration.inMinutes.toString().padLeft(2, '0')}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  context,
                ).colorScheme.inverseSurface.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> showMenu(BuildContext context, TapDownDetails e) =>
      showOverlayMenu(
        context: context,
        style: .new(itemStyle: .new(height: 30), padding: .zero),
        offset: e.localPosition.translate(0, -context.size!.height),
        items: [
          OverlayMenuItem(
            child: Padding(
              padding: const .symmetric(horizontal: 10),
              child: Text('Добавить в очередь'),
            ),
            onTap: () => audioPlayer.addToQueue(track),
          ),
          OverlayMenuItem(
            child: Padding(
              padding: const .symmetric(horizontal: 10),
              child: Text('Играть следующим'),
            ),
            onTap: () => audioPlayer.addNext(track),
          ),
          OverlayMenuItem(
            child: Padding(
              padding: const .symmetric(horizontal: 10),
              child: Text('Убрать из списка'),
            ),
            onTap: () => playlist.remove(track),
          ),
        ],
      );
}
