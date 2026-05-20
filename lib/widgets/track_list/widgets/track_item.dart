import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';

import '../../../core/audio_player/audio_player.dart';
import '../../../core/audio_player/track.dart';
import '../../../core/config.dart';
import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../playlists_page/add_to_playlist_button.dart';
import '../../simple_menu.dart';
import 'track_details.dart';

class TrackItem extends StatefulWidget {
  const TrackItem(
    this.track, {
    required this.onSelected,
    super.key,
    this.menuItems,
  });

  final Track track;
  final List<SimpleMenuItem>? menuItems;
  final void Function() onSelected;

  @override
  State<TrackItem> createState() => _TrackItemState();
}

class _TrackItemState extends State<TrackItem>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription isPlayingSub;
  late final StreamSubscription trackSub;

  Track get track => widget.track;
  bool get isSelected => audioPlayer.currentTrack == track;
  bool get isPlaying => isSelected && audioPlayer.isPlaying;

  @override
  void initState() {
    super.initState();
    isPlayingSub = audioPlayer.stream.isPlaying
        .map((e) => isSelected && e)
        .distinct()
        .listen(
          (_) => () {
            setState(() {});
          }(),
        );
    trackSub = audioPlayer.stream.currentTrack
        .map((e) => e == track)
        .distinct()
        .listen(
          (_) => () {
            setState(() {});
          }(),
        );
  }

  @override
  void dispose() {
    isPlayingSub.cancel();
    trackSub.cancel();
    super.dispose();
  }

  Future<void> playPressed() async {
    if (isSelected) {
      if (isPlaying) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }
    } else {
      widget.onSelected();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: .opaque,
    onSecondaryTapDown: (e) => showMenu(context, e),
    child: Card(
      clipBehavior: .hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: isSelected ? BorderSide(color: colorScheme.primary) : .none,
      ),
      child: Padding(
        padding: const .only(left: 6, right: 10),
        child: Row(
          spacing: 8,
          children: [
            _buildIcon(),
            _buildText(),
            _buildButtons(),
            Text(
              '${track.duration.inMinutes.toString().padLeft(2, '0')}'
              ':'
              '${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Container _buildIcon() => Container(
    width: 30,
    height: 30,
    clipBehavior: .hardEdge,
    decoration: BoxDecoration(
      borderRadius: .circular(8),
      border: .all(strokeAlign: 1, width: 1, color: Colors.grey.shade600),
    ),
    child: Stack(
      fit: .expand,
      alignment: .center,
      children: [
        if (track.picture != null)
          Image.memory(track.picture!.bytes)
        else
          Icon(Icons.music_note_rounded, color: Colors.grey.shade400, size: 20),
        _PlayButton(isPlaying: isPlaying, onPressed: playPressed),
      ],
    ),
  );

  Expanded _buildText() => Expanded(
    child: RichText(
      text: TextSpan(
        text: '${track.title}  ',
        children: [
          TextSpan(
            text: track.author,
            style: .new(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(170),
            ),
          ),
        ],
      ),
      overflow: .ellipsis,
    ),
  );

  Row _buildButtons() => Row(
    children: [
      if (playlists.isNotEmpty)
        AddToPlaylistButton(
          track: track,
          padding: const .all(6),
          builder: (context) => Icon(
            mainPlaylist?.tracks.contains(track) ??
                    playlists.where((e) => e.tracks.contains(track)).isNotEmpty
                ? Icons.playlist_add_check_rounded
                : Icons.playlist_add_rounded,
            size: 20,
            color: colorScheme.onSurface.withAlpha(200),
          ),
          countBuilder: (context, child) =>
              Transform.translate(offset: const .new(-12, 8), child: child),
        ),
      IconButton(
        onPressed: () => audioPlayer.addNext(track),
        icon: const Icon(Icons.navigate_next_rounded),
        color: colorScheme.onSurface.withAlpha(200),
        style: ButtonStyle(
          minimumSize: .all(Size.zero),
          iconSize: .all(24),
          padding: .all(const .all(4)),
        ),
      ),
    ],
  );

  Future<void> showMenu(BuildContext context, TapDownDetails e) async {
    final controller = OverlayMenuController();
    await showOverlayMenu(
      context: context,
      controller: controller,
      style: overlayMenuStyle,
      offset: e.localPosition.translate(0, -context.size!.height),
      items: [
        SimpleMenuItem(
          text: 'Добавить в очередь',
          onTap: () => audioPlayer.addToQueue(track),
        ).toOverlayItem(),
        SimpleMenuItem(
          text: 'Играть следующим',
          onTap: () => audioPlayer.addNext(track),
        ).toOverlayItem(),
        if (playlists.isNotEmpty)
          OverlayMenuItem(
            child: OverlayMenuButton(
              position: .right,
              style: overlayMenuStyle,
              items: playlists
                  .where((e) => !e.tracks.contains(track))
                  .map(
                    (e) => SimpleMenuItem(
                      text: e.title,
                      onTap: () {
                        e.tracks.add(track);
                        trackPlaylistChanged.add(track);
                        controller.close();
                      },
                    ).toOverlayItem(),
                  )
                  .followedBy(
                    playlists
                        .where((e) => e.tracks.contains(track))
                        .map(
                          (e) => SimpleMenuItem(
                            text: '-${e.title}',
                            onTap: () {
                              e.tracks.remove(track);
                              trackPlaylistChanged.add(track);
                              controller.close();
                            },
                          ).toOverlayItem(),
                        ),
                  )
                  .toList(),
              child: const Padding(
                padding: .symmetric(horizontal: 10),
                child: Text('Добавить в плейлист'),
              ),
            ),
          ),
        if (widget.menuItems != null)
          ...widget.menuItems!.map((e) => e.toOverlayItem()),
        SimpleMenuItem(
          text: 'Свойства',
          onTap: () => showDialog(
            context: context,
            builder: (context) => TrackDetails(track),
          ),
        ).toOverlayItem(),
      ],
    );
    controller.close();
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.isPlaying, required this.onPressed});

  final void Function() onPressed;
  final bool isPlaying;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController playAnim = .new(
    vsync: this,
    duration: Durations.short2,
    value: isVisible ? 1 : 0,
  );
  var isHovered = false;

  bool get isPlaying => widget.isPlaying;
  bool get isVisible => isHovered || isPlaying;

  @override
  void didUpdateWidget(covariant _PlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    playAnim.animateTo(isPlaying ? 1 : 0);
  }

  @override
  void dispose() {
    playAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => isHovered = true),
    onExit: (_) => setState(() => isHovered = false),
    child: GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: Durations.short2,
        child: ColoredBox(
          color: colorScheme.surface.withAlpha(100),
          child: Center(
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              size: 20,
              color: colorScheme.onSurface,
              progress: playAnim,
            ),
          ),
        ),
      ),
    ),
  );
}
