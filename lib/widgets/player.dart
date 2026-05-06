import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';

import '../audio_player.dart';
import 'player/position_slider.dart';
import 'player/volume_button.dart';

class Player extends StatefulWidget {
  const Player({super.key});

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> with SingleTickerProviderStateMixin {
  late final StreamSubscription subscription;
  late final AnimationController playAnim = .new(
    vsync: this,
    duration: Durations.short2,
  );
  double nextBtnOffset = 0;
  double prevBtnOffset = 0;

  @override
  void initState() {
    super.initState();
    subscription = audioPlayer.stream.isPlaying.listen((_) {
      setState(() {});
      playAnim.animateTo(audioPlayer.isPlaying ? 1 : 0);
    });
  }

  @override
  Future<void> dispose() async {
    playAnim.dispose();
    super.dispose();
    await subscription.cancel();
    await audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) => audioPlayer.currentIndex != null
      ? Card(
          clipBehavior: .hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: .circular(12),
            side: BorderSide(
              color: audioPlayer.isPlaying
                  ? Theme.of(context).colorScheme.primary.withAlpha(200)
                  : Theme.of(context).colorScheme.secondary.withAlpha(100),
            ),
          ),
          elevation: 2,
          child: Column(
            children: [
              Padding(
                padding: const .only(top: 8, right: 8, left: 8, bottom: 4),
                child: Row(
                  mainAxisAlignment: .center,
                  children: [
                    Expanded(child: trackInfo(context)),
                    controlButtons(),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: .end,
                        children: [inputDeviceButton(), VolumeButton()],
                      ),
                    ),
                  ],
                ),
              ),
              PositionSlider(),
            ],
          ),
        )
      : SizedBox();

  Widget trackInfo(BuildContext context) => StreamBuilder(
    stream: audioPlayer.stream.currentTrack,
    builder: (context, asyncSnapshot) => Row(
      mainAxisSize: .min,
      spacing: 8,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: .circular(6),
            border: .all(color: Colors.grey.shade600, width: 1, strokeAlign: 1),
          ),
          height: 40,
          width: 40,
          clipBehavior: .hardEdge,
          child: audioPlayer.currentTrack!.picture != null
              ? Image.memory(audioPlayer.currentTrack!.picture!.bytes)
              : Icon(Icons.music_note_rounded, color: Colors.grey.shade400),
        ),
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(audioPlayer.currentTrack!.title, overflow: .fade),
            Text(
              audioPlayer.currentTrack!.author,
              softWrap: true,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.inverseSurface.withAlpha(170),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget controlButtons() => Row(
    mainAxisAlignment: .center,
    children: [
      /// Shuffle
      StreamBuilder(
        stream: audioPlayer.stream.shuffled,
        builder: (context, asyncSnapshot) => IconButton(
          color: audioPlayer.shuffled
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: () => audioPlayer.setShuffled(!audioPlayer.shuffled),
          icon: const Icon(Icons.shuffle_rounded),
        ),
      ),

      /// Previous
      StatefulBuilder(
        builder: (context, setState) => AnimatedSlide(
          offset: Offset(-prevBtnOffset / 10, 0),
          duration: Durations.short2,
          onEnd: () {
            if (prevBtnOffset != 0) {
              setState(() => prevBtnOffset = 0);
            }
          },
          child: IconButton(
            color: prevBtnOffset != 0
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: () => setState(() {
              prevBtnOffset = 1;
              audioPlayer.previous();
            }),
            icon: const Icon(Icons.skip_previous_rounded),
          ),
        ),
      ),

      /// Play/Pause
      IconButton(
        onPressed: () =>
            audioPlayer.isPlaying ? audioPlayer.pause() : audioPlayer.play(),
        icon: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: playAnim,
          // audioPlayer.isPlaying
          //     ? Icons.pause_circle_outline_rounded
          //     : Icons.play_circle_fill_rounded,
        ),
      ),

      /// Next
      StatefulBuilder(
        builder: (context, setState) => AnimatedSlide(
          offset: Offset(nextBtnOffset / 10, 0),
          duration: Durations.short2,
          onEnd: () {
            if (nextBtnOffset != 0) {
              setState(() => nextBtnOffset = 0);
            }
          },
          child: IconButton(
            color: nextBtnOffset != 0
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: () => setState(() {
              nextBtnOffset = 1;
              audioPlayer.next();
            }),
            icon: const Icon(Icons.skip_next_rounded),
          ),
        ),
      ),

      /// Loop
      StreamBuilder(
        stream: audioPlayer.stream.looped,
        builder: (context, asyncSnapshot) => AnimatedRotation(
          duration: Durations.short3,
          turns: audioPlayer.looped ? -0.5 : 0,
          child: IconButton(
            color: audioPlayer.looped
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: () => audioPlayer.setLooped(!audioPlayer.looped),
            icon: const Icon(Icons.loop_rounded),
          ),
        ),
      ),
    ],
  );

  Widget inputDeviceButton() => Builder(
    builder: (context) => IconButton(
      onPressed: () async {
        var device = await showOverlayMenu(
          context: context,
          initialValue: audioPlayer.audioDevice,
          style: .new(padding: .zero, itemStyle: .new(height: 30)),
          items: audioPlayer.audioDevices
              .map(
                (e) => OverlayMenuItem(
                  child: Padding(
                    padding: const .symmetric(horizontal: 8),
                    child: Text(e.description, style: .new(fontSize: 12)),
                  ),
                  value: e,
                  enabled: e != audioPlayer.audioDevice,
                ),
              )
              .toList(),
        );
        if (device != null) {
          audioPlayer.setAudioDevice(device);
        }
      },
      icon: const Icon(Icons.input_rounded),
    ),
  );
}
