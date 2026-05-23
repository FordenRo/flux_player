import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/audio_player/audio_player.dart';
import '../../../core/models/track.dart';
import '../track_list_controller.dart';

class FloatingActionsOverlay extends StatefulWidget {
  const FloatingActionsOverlay({
    required this.listController,
    required this.tracks,
    super.key,
  });
  final TrackListController listController;
  final List<Track> tracks;

  @override
  State<FloatingActionsOverlay> createState() => _FloatingActionsOverlayState();
}

class _FloatingActionsOverlayState extends State<FloatingActionsOverlay> {
  TrackListController get controller => widget.listController;

  late bool showWatchTrack = canShowWatchTrack();
  late bool showGoTop = canShowGoTop();
  late bool watchCurrentTrack = controller.watchCurrentTrack;
  late final StreamSubscription subscription;

  bool canShowWatchTrack() => audioPlayer.currentTrack != null;
  bool canShowGoTop() => controller.offset > 500;

  @override
  void initState() {
    super.initState();

    controller.addListener(update);
    subscription = audioPlayer.stream.currentIndex.listen((_) => update());
  }

  void update() {
    final canShowWatch = canShowWatchTrack();
    final canShowTop = canShowGoTop();
    if (canShowWatch != showWatchTrack ||
        canShowTop != showGoTop ||
        controller.watchCurrentTrack != watchCurrentTrack) {
      setState(() {
        showWatchTrack = canShowWatch;
        showGoTop = canShowTop;
        watchCurrentTrack = controller.watchCurrentTrack;
      });
    }
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    spacing: 4,
    children: [
      AnimatedSlide(
        offset: Offset(0, showWatchTrack ? 0 : 1.4),
        duration: Durations.medium1,
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: showGoTop ? 1 : 0,
          duration: Durations.medium1,
          child: IconButton.filled(
            onPressed: showGoTop ? controller.animateToTop : null,
            iconSize: 20,
            padding: .zero,
            splashRadius: 10,
            visualDensity: .compact,
            style: .new(
              backgroundColor: .all(
                Color.alphaBlend(
                  Theme.of(context).colorScheme.secondary.withAlpha(100),
                  Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
            color: Theme.of(context).colorScheme.onSurface,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ),
      ),
      AnimatedOpacity(
        opacity: showWatchTrack ? 1 : 0,
        duration: Durations.medium1,
        child: IconButton.filled(
          onPressed: showWatchTrack
              ? () {
                  controller.watchCurrentTrack = !controller.watchCurrentTrack;
                  update();
                }
              : null,
          iconSize: 22,
          padding: .zero,
          splashRadius: 10,
          visualDensity: .comfortable,
          style: .new(
            backgroundColor: .all(
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withAlpha(120),
                Theme.of(context).colorScheme.surface,
              ),
            ),
            side: .all(
              watchCurrentTrack
                  ? .new(
                      color: Color.alphaBlend(
                        Theme.of(context).colorScheme.onSurface.withAlpha(180),
                        Theme.of(context).colorScheme.surface,
                      ),
                      width: 2,
                    )
                  : .none,
            ),
          ),
          color: Theme.of(context).colorScheme.onSurface,
          icon: const Icon(Icons.music_note_rounded),
        ),
      ),
    ],
  );
}
