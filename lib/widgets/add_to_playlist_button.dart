import 'package:flutter/material.dart';

import '../core/audio_player/track.dart';
import '../core/config.dart';
import '../features/simple_menu.dart';

class AddToPlaylistButton extends StatefulWidget {
  final Track track;
  final Widget Function(BuildContext context) builder;

  const AddToPlaylistButton({
    super.key,
    required this.track,
    required this.builder,
  });

  @override
  State<AddToPlaylistButton> createState() => _AddToPlaylistButtonState();
}

class _AddToPlaylistButtonState extends State<AddToPlaylistButton> {
  Track get track => widget.track;

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
  }

  @override
  Widget build(BuildContext context) => InkWell(
    customBorder: CircleBorder(),
    onTap: onTap,
    onSecondaryTap: onSecondaryTap,
    child: Padding(
      padding: const .all(8),
      child: Builder(builder: widget.builder),
    ),
  );
}
