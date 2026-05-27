import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/audio_player/audio_player.dart';
import '../../../../core/theme/theme.dart';

class VolumeOverlay extends StatefulWidget {
  const VolumeOverlay._({required this.onHide, required this._controller});

  final void Function() onHide;
  final _VolumeOverlayController _controller;

  static VolumeOverlayEntry createOverlay(BuildContext context) {
    final controller = _VolumeOverlayController();
    final entry = VolumeOverlayEntry._(context, controller: controller);
    entry.entry = .new(
      builder: (context) =>
          VolumeOverlay._(onHide: entry.remove, controller: controller),
    );
    return entry;
  }

  @override
  State<VolumeOverlay> createState() => _VolumeOverlayState();
}

class _VolumeOverlayController with ChangeNotifier {
  var _isButtonHovered = false;

  bool get isButtonHovered => _isButtonHovered;
  set isButtonHovered(bool hovered) {
    _isButtonHovered = hovered;
    notifyListeners();
  }
}

class VolumeOverlayEntry {
  VolumeOverlayEntry._(this.context, {required this._controller});

  late final OverlayEntry entry;
  final _VolumeOverlayController _controller;
  final BuildContext context;

  bool get isButtonHovered => _controller.isButtonHovered;
  set isButtonHovered(bool hovered) {
    _controller.isButtonHovered = hovered;
    if (hovered) show();
  }

  void show() {
    if (!entry.mounted) Overlay.of(context).insert(entry);
  }

  void remove() {
    if (entry.mounted) entry.remove();
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
  Timer? timer;
  late final StreamSubscription subscription;

  _VolumeOverlayController get controller => widget._controller;
  bool get isButtonHovered => controller.isButtonHovered;

  @override
  void initState() {
    super.initState();
    subscription = audioPlayer.stream.volume.listen((_) => setState(() {}));
    controller.addListener(_onControllerUpdate);
    _show();
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    fadeAnimation.dispose();
    timer?.cancel();
    subscription.cancel();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (isButtonHovered) {
      _show();
    } else {
      _hideDelayed();
    }
  }

  Future<void> _show() {
    timer?.cancel();
    fadeAnimation.stop();
    return fadeAnimation.animateTo(1, curve: Curves.easeInOut);
  }

  Future<void> _hide() async {
    if (sliding || hovered || isButtonHovered) return;

    await fadeAnimation
        .animateTo(0, curve: Curves.easeInOut)
        .then((_) => widget.onHide());
  }

  void _hideDelayed() {
    if (sliding || hovered || isButtonHovered) return;

    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), _hide);
  }

  Builder _buildCard() => Builder(
    builder: (context) => Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.secondary.withAlpha(100),
        ),
        borderRadius: Radiuses.r12,
      ),
      elevation: 8,
      child: SliderTheme(
        data: SliderThemeData(
          activeTrackColor: Theme.of(
            context,
          ).colorScheme.primary.withAlpha(200),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        ),
        child: Slider(
          value: audioPlayer.volume,
          onChangeStart: (_) => sliding = true,
          onChangeEnd: (_) {
            sliding = false;
            _hideDelayed();
          },
          onChanged: audioPlayer.setVolume,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Align(
    alignment: .bottomRight,
    child: Transform.translate(
      offset: const Offset(15, -55),
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
              _show();
            },
            onExit: (event) {
              hovered = false;
              _hideDelayed();
            },
            child: Center(
              child: SizedBox(
                width: 200,
                height: 50,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
