import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../music_controller.dart';
import 'volume_control.dart';

class Player extends StatefulWidget {
  const Player({super.key});

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  OverlayEntry? volumeOverlay;
  Timer? volumeHoverTimer;
  var hovered = false;

  @override
  void initState() {
    super.initState();

    audioPlayer.stream
      ..isPlaying.listen((_) => setState(() {}))
      ..currentIndex.listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    removeVolumeOverlay();
    super.dispose();
  }

  void createVolumeOverlay() {
    removeVolumeOverlay();

    volumeOverlay = OverlayEntry(
      builder: (context) => VolumeControl(onExit: removeVolumeOverlay),
    );
    Overlay.of(context).insert(volumeOverlay!);
  }

  void removeVolumeOverlay() {
    volumeHoverTimer?.cancel();
    volumeOverlay?.remove();
    volumeOverlay?.dispose();
    volumeOverlay = null;
  }

  @override
  Widget build(BuildContext context) => audioPlayer.currentIndex != null
      ? MouseRegion(
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: Card(
            clipBehavior: .hardEdge,
            elevation: 2,
            child: Column(
              children: [
                Padding(
                  padding: const .all(8),
                  child: Row(
                    mainAxisAlignment: .center,
                    children: [
                      Expanded(child: buildInfo(context)),
                      buildControls(),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: .end,
                          children: [
                            IconButton(
                              onHover: (hovered) {
                                if (hovered) {
                                  volumeHoverTimer = Timer(
                                    Duration(milliseconds: 300),
                                    createVolumeOverlay,
                                  );
                                } else {
                                  volumeHoverTimer?.cancel();
                                }
                              },
                              onPressed: createVolumeOverlay,
                              icon: const Icon(Icons.volume_up_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TrackPosition(expanded: hovered),
              ],
            ),
          ),
        )
      : SizedBox();

  Row buildInfo(BuildContext context) => Row(
    children: [
      audioPlayer.currentTrack!.picture != null
          ? Image.memory(
              Uint8List.fromList(audioPlayer.currentTrack!.picture!.data),
              width: 64,
            )
          : SizedBox(),
      Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(audioPlayer.currentTrack!.title),
          Text(
            audioPlayer.currentTrack!.author,
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
  );

  Row buildControls() => Row(
    mainAxisAlignment: .center,
    children: [
      IconButton(
        onPressed: () => audioPlayer.setShuffled(!audioPlayer.shuffled),
        icon: const Icon(Icons.shuffle_rounded),
      ),
      IconButton(
        // onPressed: audioPlayer.seekToPrevious,
        onPressed: audioPlayer.previous,
        icon: const Icon(Icons.skip_previous_rounded),
      ),
      IconButton(
        onPressed: () =>
            audioPlayer.isPlaying ? audioPlayer.pause() : audioPlayer.play(),
        icon: Icon(
          // audioPlayer.playing
          audioPlayer.isPlaying
              ? Icons.pause_circle_outline_rounded
              : Icons.play_circle_fill_rounded,
        ),
      ),
      IconButton(
        // onPressed: audioPlayer.seekToNext,
        onPressed: audioPlayer.next,
        icon: const Icon(Icons.skip_next_rounded),
      ),
      IconButton(onPressed: () {}, icon: const Icon(Icons.loop_rounded)),
    ],
  );
}

class TrackPosition extends StatefulWidget {
  final bool expanded;

  const TrackPosition({super.key, required this.expanded});

  @override
  State<TrackPosition> createState() => _TrackPositionState();
}

class _TrackPositionState extends State<TrackPosition>
    with SingleTickerProviderStateMixin {
  late final animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );
  late final heightAnimation = Tween<double>(
    begin: 1,
    end: 2,
  ).animate(animationController);
  var position = 0.0;
  var duration = 0.0;
  var hovered = false;
  var sliding = false;

  bool get expanded => hovered || sliding;

  @override
  void initState() {
    super.initState();

    audioPlayer
      ..stream.position.listen(
        (e) => setState(() => position = e.inMilliseconds / 1000),
      )
      ..stream.duration.listen(
        (e) => setState(() => duration = e.inMilliseconds / 1000),
      );
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translation(Vector3(0, expanded ? 0 : 3, 0)),
      height: expanded ? 10 : 8,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 8,
          padding: .all(0),
          activeTrackColor: Theme.of(
            context,
          ).colorScheme.primary.withAlpha(200),
          thumbColor: Theme.of(context).colorScheme.primary,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: expanded ? 6 : 0,
            elevation: 4,
          ),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: Slider(
          value: duration > 0 ? max(min(position / duration, 1), 0) : 0,
          onChangeStart: (_) => setState(() => sliding = true),
          onChangeEnd: (_) => setState(() => sliding = false),
          onChanged: (e) => audioPlayer.seek(
            Duration(milliseconds: (e * duration * 1000).toInt()),
          ),
        ),
      ),
    ),
  );
}
