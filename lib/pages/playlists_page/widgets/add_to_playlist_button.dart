import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/track.dart';
import '../../../core/services/config_service.dart';
import '../../../core/utils.dart';
import '../../../widgets/simple_menu.dart';

class AddToPlaylistButton extends StatefulWidget {
  const AddToPlaylistButton({
    required this.track,
    required this.iconBuilder,
    required this.countBuilder,
    this.padding = const .all(8),
    super.key,
  });

  final Track track;
  final EdgeInsets padding;
  final Widget Function(BuildContext context) iconBuilder;
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
      if (track == e) setState(() {});
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  Future<void> _onTap() async {
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

  void _onSecondaryTap() {
    if (mainPlaylist == null) return;

    if (mainPlaylist!.tracks.contains(track)) {
      setState(() => mainPlaylist!.tracks.remove(track));
    } else {
      setState(() => mainPlaylist!.tracks.add(track));
    }
    trackPlaylistChanged.add(track);
  }

  Builder _buildCount(int playlistCount) => Builder(
    builder: (context) => widget.countBuilder(
      context,
      Text(
        playlistCount.toString(),
        style: .new(
          fontSize: 9,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final playlistCount = playlists
        .where((e) => e.tracks.contains(track))
        .length;

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: _onTap,
      onSecondaryTap: _onSecondaryTap,
      child: Padding(
        padding: widget.padding,
        child: Stack(
          alignment: .center,
          children: [
            Builder(builder: widget.iconBuilder),
            if (playlistCount > 0) _buildCount(playlistCount),
          ],
        ),
      ),
    );
  }
}
