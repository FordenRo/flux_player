import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../audio_player.dart';
import 'volume_overlay.dart';

class Player extends StatefulWidget {
  const Player({super.key});

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late final StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    subscription = audioPlayer.stream.isPlaying.listen((_) => setState(() {}));
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await audioPlayer.dispose();
    await subscription.cancel();
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
                padding: const .all(8),
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
              TrackPosition(),
            ],
          ),
        )
      : SizedBox();

  Builder inputDeviceButton() => Builder(
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

  Widget trackInfo(BuildContext context) => StreamBuilder(
    stream: audioPlayer.stream.currentTrack,
    builder: (context, asyncSnapshot) => Row(
      mainAxisSize: .min,
      children: [
        audioPlayer.currentTrack!.picture != null
            ? Image.memory(
                Uint8List.fromList(audioPlayer.currentTrack!.picture!.data),
                width: 64,
              )
            : SizedBox(width: 2),
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
      IconButton(
        onPressed: audioPlayer.previous,
        icon: const Icon(Icons.skip_previous_rounded),
      ),

      /// Play/Pause
      IconButton(
        onPressed: () =>
            audioPlayer.isPlaying ? audioPlayer.pause() : audioPlayer.play(),
        icon: Icon(
          audioPlayer.isPlaying
              ? Icons.pause_circle_outline_rounded
              : Icons.play_circle_fill_rounded,
        ),
      ),

      /// Next
      IconButton(
        onPressed: audioPlayer.next,
        icon: const Icon(Icons.skip_next_rounded),
      ),

      /// Loop
      StreamBuilder(
        stream: audioPlayer.stream.looped,
        builder: (context, asyncSnapshot) => IconButton(
          color: audioPlayer.looped
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: () => audioPlayer.setLooped(!audioPlayer.looped),
          icon: const Icon(Icons.loop_rounded),
        ),
      ),
    ],
  );
}

class TrackPosition extends StatefulWidget {
  const TrackPosition({super.key});

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
  late final List<StreamSubscription> subscriptions;
  double position = audioPlayer.position.inMilliseconds / 1000;
  double duration = audioPlayer.duration.inMilliseconds / 1000;
  var hovered = false;
  var sliding = false;

  bool get expanded => hovered || sliding;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      audioPlayer.stream.position.listen(
        (e) => setState(() => position = e.inMilliseconds / 1000),
      ),
      audioPlayer.stream.duration.listen(
        (e) => setState(() => duration = e.inMilliseconds / 1000),
      ),
    ];
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await Future.wait(subscriptions.map((e) => e.cancel()));
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

class VolumeButton extends StatefulWidget {
  const VolumeButton({super.key});

  @override
  State<VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<VolumeButton> {
  late final volumeOverlay = VolumeOverlay.createOverlay(context);
  late final StreamSubscription subscription;
  Timer? hoverTimer;
  double? lastVolume;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    volumeOverlay.dispose();
    hoverTimer?.cancel();
    super.dispose();
  }

  IconData getIconDataFromVolume(double volume) => switch (volume) {
    > .7 => Icons.volume_up_rounded,
    > .3 => Icons.volume_down_rounded,
    > 0 => Icons.volume_mute_rounded,
    _ => Icons.volume_off_rounded,
  };

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: (e) {
      if (e is PointerScrollEvent) {
        audioPlayer.setVolume(audioPlayer.volume - e.scrollDelta.dy / 5000);
      }
    },
    child: StreamBuilder(
      stream: audioPlayer.stream.volume.map(getIconDataFromVolume).distinct(),
      builder: (context, snapshot) => IconButton(
        onHover: (hovered) {
          if (hovered) {
            hoverTimer = Timer(Duration(milliseconds: 300), volumeOverlay.show);
          } else {
            hoverTimer?.cancel();
          }
        },
        onPressed: () {
          if (audioPlayer.volume > 0) {
            lastVolume = audioPlayer.volume;
            audioPlayer.setVolume(0);
          } else if (lastVolume != null) {
            audioPlayer.setVolume(lastVolume!);
          }
        },
        icon: Icon(snapshot.data ?? getIconDataFromVolume(audioPlayer.volume)),
      ),
    ),
  );
}
