import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/audio_player/audio_player.dart';
import 'volume_overlay.dart';

class VolumeButton extends StatefulWidget {
  const VolumeButton({super.key});

  @override
  State<VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<VolumeButton> {
  late final volumeOverlay = VolumeOverlay.createOverlay(context);
  Timer? hoverTimer;
  double? lastVolume;

  @override
  void dispose() {
    volumeOverlay.dispose();
    hoverTimer?.cancel();
    super.dispose();
  }

  IconData _getIconDataFromVolume(double volume) => switch (volume) {
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
      stream: audioPlayer.stream.volume.map(_getIconDataFromVolume).distinct(),
      initialData: _getIconDataFromVolume(audioPlayer.volume),
      builder: (context, snapshot) => IconButton(
        onHover: (hovered) {
          if (hovered) {
            hoverTimer = Timer(
              Durations.short3,
              () => volumeOverlay.isButtonHovered = hovered,
            );
          } else {
            volumeOverlay.isButtonHovered = false;
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
        icon: Icon(snapshot.requireData),
      ),
    ),
  );
}
