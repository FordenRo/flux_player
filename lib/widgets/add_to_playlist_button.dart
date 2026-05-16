import 'dart:async';

import 'package:flutter/material.dart';

import '../core/audio_player/track.dart';
import '../core/config.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../features/simple_menu.dart';

class AddToPlaylistButton extends StatefulWidget {
  const AddToPlaylistButton({
    required this.track,
    required this.builder,
    required this.countBuilder,
    super.key,
  });
  final Track track;
  final Widget Function(BuildContext context) builder;
  final Widget Function(BuildContext context, Widget child) countBuilder;

  @override
  State<AddToPlaylistButton> createState() => _AddToPlaylistButtonState();
}

class _AddToPlaylistButtonState extends State<AddToPlaylistButton> {
  late final StreamSubscription subscription;
  Track get track => widget.track;

  @override
  void initState() {
    super.initState();
    subscription = trackPlaylistChanged.stream.listen((e) {
      if (track == e) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  Future<void> onTap() async {
    final isSelected = await showSimpleMenu(
      context: context,
      items: playlists
          .where((e) => !e.tracks.contains(track))
          .map(
            (e) => SimpleMenuItem(
              text: e.title,
              value: true,
              onTap: () => e.tracks.add(track),
            ),
          )
          .followedBy(
            playlists
                .where((e) => e.tracks.contains(track))
                .map(
                  (e) => SimpleMenuItem(
                    text: '-${e.title}',
                    value: true,
                    onTap: () => e.tracks.remove(track),
                  ),
                ),
          )
          .toList(),
    );
    if (isSelected != null) {
      trackPlaylistChanged.add(track);
      setState(() {});
    }
  }

  void onSecondaryTap() {
    if (mainPlaylist == null) {
      return;
    }
    if (mainPlaylist!.tracks.contains(track)) {
      setState(() => mainPlaylist!.tracks.remove(track));
    } else {
      setState(() => mainPlaylist!.tracks.add(track));
    }
    trackPlaylistChanged.add(track);
  }

  @override
  Widget build(BuildContext context) {
    final playlistCount = playlists
        .where((e) => e.tracks.contains(track))
        .length;

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      onSecondaryTap: onSecondaryTap,
      child: Padding(
        padding: const .all(8),
        child: Stack(
          alignment: .center,
          children: [
            Builder(builder: widget.builder),
            if (playlistCount > 0)
              Builder(
                builder: (context) => widget.countBuilder(
                  context,
                  Text(
                    playlistCount.toString(),
                    style: .new(
                      fontSize: 9,
                      color: colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
