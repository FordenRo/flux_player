import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../music_controller.dart';

class VolumeControl extends StatefulWidget {
  final void Function() onExit;

  const VolumeControl({super.key, required this.onExit});

  static OverlayEntry createOverlay(
    BuildContext context, {
    required void Function() onExit,
  }) {
    var entry = OverlayEntry(
      builder: (context) => VolumeControl(onExit: onExit),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl>
    with SingleTickerProviderStateMixin {
  late final animationController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );
  late final Animation<double> fadeAnimation = Tween(begin: 0.0, end: 1.0)
      .animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      );
  var _canExit = false;
  Timer? timer;
  late final StreamSubscription subscription;

  bool get canExit => _canExit;

  set canExit(bool v) {
    _canExit = v;
    v ? timer = Timer(const Duration(seconds: 5), close) : timer?.cancel();
  }

  @override
  void initState() {
    super.initState();

    animationController.forward();
    canExit = true;
    subscription = audioPlayer.stream.volume.listen((_) => setState(() {}));
  }

  @override
  Future<void> dispose() async {
    animationController.dispose();
    timer?.cancel();
    super.dispose();
    await subscription.cancel();
  }

  void close() async {
    if (!canExit) {
      return;
    }

    await animationController.animateBack(0);
    widget.onExit();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: .bottomRight,
    child: Transform.translate(
      offset: Offset(15, -55),
      child: SizedBox(
        width: 250,
        height: 100,
        child: Listener(
          onPointerSignal: (e) async {
            if (e is PointerScrollEvent) {
              await audioPlayer.setVolume(
                audioPlayer.volume - e.scrollDelta.dy / 5000,
              );
            }
          },
          child: MouseRegion(
            // onEnter: (event) => canExit = true,
            onExit: (event) => close(),
            child: Center(
              child: SizedBox(
                width: 200,
                height: 50,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withAlpha(100),
                      ),
                      borderRadius: .circular(16),
                    ),
                    elevation: 8,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(200),
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: audioPlayer.volume,
                        onChangeStart: (_) => canExit = false,
                        onChangeEnd: (_) => canExit = true,
                        onChanged: audioPlayer.setVolume,
                      ),
                    ),
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
