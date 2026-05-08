import 'dart:async';
import 'package:flutter/material.dart';
import '../../audio_player.dart';

class TrackListController extends ScrollController {
  var watchCurrentTrack = true;
  List<AudioTrack> tracks;
  late final StreamSubscription _subscription;

  TrackListController(this.tracks, {super.onAttach, super.onDetach}) {
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

  Future<void> animateToTrack(AudioTrack track) => animateTo(
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
