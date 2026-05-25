import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../../../core/audio_player/audio_player.dart';

class PositionSlider extends StatefulWidget {
  const PositionSlider({super.key});

  @override
  State<PositionSlider> createState() => _PositionSliderState();
}

class _PositionSliderState extends State<PositionSlider> {
  late final StreamController stream;

  var hovered = false;
  var sliding = false;

  bool get expanded => hovered || sliding;
  double get position => audioPlayer.position.inMilliseconds / 1000;
  double get duration => audioPlayer.duration.inMilliseconds / 1000;

  @override
  void initState() {
    super.initState();
    stream = .broadcast()
      ..addStream(
        audioPlayer.stream.position,
      ).then((_) => stream.addStream(audioPlayer.stream.duration));
  }

  @override
  void dispose() {
    stream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (e) => setState(() => hovered = true),
    onExit: (e) => setState(() => hovered = false),
    child: Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          audioPlayer.seek(
            Duration(
              milliseconds: (position * 1000 - e.scrollDelta.dy * 10).toInt(),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translation(Vector3(0, expanded ? 0 : 3, 0)),
        height: expanded ? 10 : 8,
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            padding: .zero,
            activeTrackColor: Theme.of(
              context,
            ).colorScheme.primary.withAlpha(200),
            thumbColor: Theme.of(context).colorScheme.primary,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: expanded ? 6 : 0,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: StreamBuilder(
            stream: stream.stream,
            builder: (context, asyncSnapshot) => Slider(
              value: duration > 0 ? max(min(position / duration, 1), 0) : 0,
              onChangeStart: (_) => setState(() => sliding = true),
              onChangeEnd: (_) => setState(() => sliding = false),
              onChanged: (e) => audioPlayer.seek(
                Duration(milliseconds: (e * duration * 1000).toInt()),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
