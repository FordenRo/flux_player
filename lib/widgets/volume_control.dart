import 'dart:async';

import 'package:flutter/material.dart';

import '../music_controller.dart';

class VolumeControl extends StatefulWidget {
  final void Function() onExit;

  const VolumeControl({super.key, required this.onExit});

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
  void dispose() {
    timer?.cancel();
    animationController.dispose();
    subscription.cancel();

    super.dispose();
  }

  void close() async {
    if (!canExit) {
      return;
    }

    await animationController.animateBack(0);
    widget.onExit();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: .bottomRight,
      child: Transform.translate(
        offset: Offset(15, -50),
        child: SizedBox(
          width: 250,
          height: 100,
          child: MouseRegion(
            // onEnter: (event) => canExit = true,
            onExit: (event) => close(),
            opaque: false,
            child: Center(
              child: SizedBox(
                width: 200,
                height: 50,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.white12),
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
