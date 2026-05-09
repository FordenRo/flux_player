import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/audio_player/audio_player.dart';
import '../../core/audio_player/track.dart';
import '../../core/constants.dart';
import 'track_list_controller.dart';

class FloatingActionsOverlay extends StatefulWidget {
  final TrackListController scrollController;
  final List<Track> tracks;

  const FloatingActionsOverlay({
    super.key,
    required this.scrollController,
    required this.tracks,
  });

  @override
  State<FloatingActionsOverlay> createState() => _FloatingActionsOverlayState();
}

class _FloatingActionsOverlayState extends State<FloatingActionsOverlay> {
  TrackListController get controller => widget.scrollController;
  int? get currentTrackPos => audioPlayer.currentTrack != null
      ? (widget.tracks.indexOf(audioPlayer.currentTrack!) - 1) * 50
      : null;
  bool get watchCurrentTrack => controller.watchCurrentTrack;

  late bool showWatchTrack = canShowWatchTrack();
  late bool showGoTop = canShowGoTop();
  late final StreamSubscription subscription;

  bool canShowWatchTrack() =>
      currentTrackPos != null &&
      !watchCurrentTrack &&
      (currentTrackPos! - controller.offset).abs() > 80;

  bool canShowGoTop() => controller.offset > 1000;

  @override
  void initState() {
    super.initState();

    controller.addListener(update);
    subscription = audioPlayer.stream.currentIndex.listen((_) => update());
  }

  void update() {
    var canShowWatch = canShowWatchTrack();
    var canShowTop = canShowGoTop();
    if (canShowWatch != showWatchTrack || canShowTop != showGoTop) {
      setState(() {
        showWatchTrack = canShowWatch;
        showGoTop = canShowTop;
      });
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await subscription.cancel();
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
            onPressed: controller.animateToTop,
            iconSize: 20,
            padding: .zero,
            splashRadius: 10,
            visualDensity: .compact,
            style: .new(
              backgroundColor: .all(
                Color.alphaBlend(
                  colorScheme.secondary.withAlpha(100),
                  colorScheme.surface,
                ),
              ),
            ),
            color: colorScheme.onSurface,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ),
      ),
      AnimatedOpacity(
        opacity: showWatchTrack ? 1 : 0,
        duration: Durations.medium1,
        child: IconButton.filled(
          onPressed: () {
            showWatchTrack
                ? controller.animateToTrack(audioPlayer.currentTrack!)
                : controller.animateToTop();
            controller.watchCurrentTrack = showWatchTrack;
          },
          iconSize: 22,
          padding: .zero,
          splashRadius: 10,
          visualDensity: .comfortable,
          style: .new(
            backgroundColor: .all(
              Color.alphaBlend(
                colorScheme.primary.withAlpha(120),
                colorScheme.surface,
              ),
            ),
          ),
          color: colorScheme.onSurface,
          icon: const Icon(Icons.music_note_rounded),
        ),
      ),
    ],
  );
}
