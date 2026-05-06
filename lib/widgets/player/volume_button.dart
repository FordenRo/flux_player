import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../audio_player.dart';
import 'volume_overlay.dart';

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
