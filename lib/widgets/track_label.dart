import 'dart:async';

import 'package:flutter/material.dart';

import '../music_controller.dart';

class TrackLabel extends StatefulWidget {
  const TrackLabel(this.index, {super.key});

  final int index;

  @override
  State<TrackLabel> createState() => _TrackLabelState();
}

class _TrackLabelState extends State<TrackLabel> {
  late var isSelected = audioPlayer.currentIndex == widget.index;
  late var isPlaying = isSelected && audioPlayer.isPlaying;
  late final List<StreamSubscription> subscriptions;

  AudioTrack get track => audioPlayer.audioTracks[widget.index];

  @override
  void initState() {
    super.initState();

    subscriptions = [
      audioPlayer.stream.isPlaying.listen((_) => update()),
      audioPlayer.stream.currentIndex.listen((_) => update()),
    ];
  }

  @override
  void dispose() {
    for (var e in subscriptions) {
      e.cancel();
    }
    super.dispose();
  }

  void update() {
    final selected = audioPlayer.currentIndex == widget.index;
    final playing = selected && audioPlayer.isPlaying;

    if (selected != isSelected || playing != isPlaying) {
      setState(() {
        isPlaying = playing;
        isSelected = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: .circular(12),
      side: isSelected
          ? BorderSide(color: Theme.of(context).colorScheme.primary)
          : .none,
    ),
    child: Padding(
      padding: const .all(8),
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
                await audioPlayer.jump(widget.index);
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
          Expanded(child: SizedBox()),
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
  );
}
