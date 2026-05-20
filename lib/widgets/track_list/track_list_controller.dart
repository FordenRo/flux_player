import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/audio_player/audio_player.dart';
import '../../core/models/track.dart';

class TrackListController extends ScrollController {
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

  var _watchCurrentTrack = true;
  List<Track> tracks = [];
  late final StreamSubscription _subscription;

  bool get watchCurrentTrack => _watchCurrentTrack;
  set watchCurrentTrack(bool value) {
    if (value != _watchCurrentTrack) {
      _watchCurrentTrack = value;
      if (value) {
        animateToTrack(audioPlayer.currentTrack!);
      }
    }
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

  Future<void> animateToTrack(Track track) =>
      animateToIndex(tracks.indexOf(track));

  Future<void> animateToIndex(int index) {
    final delta = _offsetOf(index) - offset;
    if (delta.abs() > 500) {
      jumpTo(_offsetOf(index) - 500 * delta.sign);
    }
    return animateTo(
      _offsetOf(index),
      duration: Durations.long2,
      curve: Curves.easeOutQuart,
    );
  }

  void jumpToTrack(Track track) => jumpToIndex(tracks.indexOf(track));

  void jumpToIndex(int index) => jumpTo(_offsetOf(index));

  double _offsetOf(int index) => index * 50 - position.viewportDimension / 3;

  Future<void> animateToTop() {
    watchCurrentTrack = false;
    return animateTo(0, duration: Durations.long2, curve: Curves.easeOutQuart);
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _subscription.cancel();
  }
}
