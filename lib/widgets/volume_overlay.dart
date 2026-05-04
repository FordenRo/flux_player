import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../audio_player.dart';

class VolumeOverlay extends StatefulWidget {
  const VolumeOverlay({super.key, required this.onHide});

  final void Function() onHide;

  static VolumeOverlayEntry createOverlay(BuildContext context) {
    var entry = VolumeOverlayEntry._internal(context);
    entry.entry = .new(
      builder: (context) => VolumeOverlay(onHide: entry.remove),
    );
    return entry;
  }

  @override
  State<VolumeOverlay> createState() => _VolumeOverlayState();
}

class VolumeOverlayEntry {
  late final OverlayEntry entry;
  final BuildContext context;

  VolumeOverlayEntry._internal(this.context);

  void show() {
    if (!entry.mounted) {
      Overlay.of(context).insert(entry);
    }
  }

  void remove() {
    if (entry.mounted) {
      entry.remove();
    }
  }

  void dispose() {
    remove();
    entry.dispose();
  }
}

class _VolumeOverlayState extends State<VolumeOverlay>
    with SingleTickerProviderStateMixin {
  late final fadeAnimation = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );
  var hovered = false;
  var sliding = false;
  late Timer timer;
  late final StreamSubscription subscription;

  @override
  void initState() {
    super.initState();

    timer = Timer(const Duration(seconds: 5), hide);
    subscription = audioPlayer.stream.volume.listen((_) => setState(() {}));
    show();
  }

  @override
  Future<void> dispose() async {
    fadeAnimation.dispose();
    timer.cancel();
    super.dispose();
    await subscription.cancel();
  }

  Future<void> show() async {
    await fadeAnimation.animateTo(1, curve: Curves.easeInOut);
  }

  Future<void> hide() async {
    if (sliding) {
      return;
    }

    await fadeAnimation.animateTo(0, curve: Curves.easeInOut);
    widget.onHide();
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
            onEnter: (event) {
              hovered = true;
              timer.cancel();
            },
            onExit: (event) {
              hovered = false;
              hide();
            },
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
                        onChangeStart: (_) => sliding = true,
                        onChangeEnd: (_) {
                          sliding = false;
                          if (!hovered) {
                            hide();
                          }
                        },
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
