import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/audio_player/audio_player.dart';
import '../../core/audio_player/track.dart';

class TrackListController extends ScrollController {
  var watchCurrentTrack = true;
  List<Track> tracks = [];
  late final StreamSubscription _subscription;

  TrackListController({super.onAttach, super.onDetach}) {
    addListener(() {
      if (watchCurrentTrack && position.userScrollDirection != .idle) {
        watchCurrentTrack = false;
      }
    });
    _subscription = audioPlayer.stream.currentIndex.listen((_) {
      if (watchCurrentTrack) {
        animateToTrack(audioPlayer.currentTrack!);
      }
    });
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);

    Future.microtask(() {
      if (watchCurrentTrack && audioPlayer.currentTrack != null) {
        animateToTrack(audioPlayer.currentTrack!);
      }
    });
  }

  Future<void> animateToTrack(Track track) => animateTo(
    (tracks.indexOf(track) - 1) * 50,
    duration: Durations.long2,
    curve: Curves.easeOutQuart,
  );

  Future<void> animateToTop() =>
      animateTo(0, duration: Durations.long2, curve: Curves.easeOutQuart);

  @override
  Future<void> dispose() async {
    super.dispose();
    await _subscription.cancel();
  }
}
