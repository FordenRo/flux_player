import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';

import '../audio_player.dart';

class TrackLabel extends StatefulWidget {
  const TrackLabel(this.playlist, this.index, {super.key, this.removeFrom});

  final List<AudioTrack> playlist;
  final void Function(AudioTrack track)? removeFrom;
  final int index;

  @override
  State<TrackLabel> createState() => _TrackLabelState();
}

class _TrackLabelState extends State<TrackLabel>
    with SingleTickerProviderStateMixin {
  late final List<StreamSubscription> subscriptions;
  late final AnimationController playAnim = .new(
    vsync: this,
    duration: Durations.short2,
    value: isPlaying ? 1 : 0,
  );

  int get index => widget.index;
  List<AudioTrack> get playlist => widget.playlist;
  AudioTrack get track => playlist[index];
  bool get isSelected => audioPlayer.currentTrack == track;
  bool get isPlaying => isSelected && audioPlayer.isPlaying;

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
    playAnim.dispose();
    super.dispose();
    await Future.wait(subscriptions.map((e) => e.cancel()));
  }

  void update() {
    setState(() {});
    playAnim.animateTo(isPlaying ? 1 : 0);
  }

  @override
  void didUpdateWidget(covariant TrackLabel oldWidget) {
    playAnim.value = isPlaying ? 1 : 0;
    super.didUpdateWidget(oldWidget);
  }

  Future<void> playPressed() async {
    if (isSelected) {
      if (isPlaying) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }
    } else {
      if (audioPlayer.queue != playlist) {
        await audioPlayer.setQueue(playlist, index: index, play: true);
      } else {
        await audioPlayer.jump(index);
      }
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
              onPressed: playPressed,
              icon: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: playAnim,
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
          if (widget.removeFrom != null)
            OverlayMenuItem(
              child: Padding(
                padding: const .symmetric(horizontal: 10),
                child: Text('Убрать из списка'),
              ),
              onTap: () => widget.removeFrom!(track),
            ),
        ],
      );
}
