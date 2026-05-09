import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';

import '../core/audio_player/audio_player.dart';
import '../core/audio_player/track.dart';
import '../core/config.dart';
import '../core/constants.dart';
import '../core/audio_player/playlist.dart';
import '../features/simple_menu.dart';

class TrackLabel extends StatefulWidget {
  const TrackLabel(this.playlist, this.index, {super.key, this.menuItems});

  final Playlist playlist;
  final List<SimpleMenuItem>? menuItems;
  final int index;

  @override
  State<TrackLabel> createState() => _TrackLabelState();
}

class _TrackLabelState extends State<TrackLabel>
    with SingleTickerProviderStateMixin {
  late final List<StreamSubscription> subscriptions;
  late final AnimationController playAnim = .new(
    vsync: this,
    duration: Durations.short2,
    value: isPlaying ? 1 : 0,
  );

  int get index => widget.index;
  Playlist get playlist => widget.playlist;
  Track get track => playlist.tracks[index];
  bool get isSelected => audioPlayer.currentTrack == track;
  bool get isPlaying => isSelected && audioPlayer.isPlaying;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      audioPlayer.stream.isPlaying
          .map((e) => isSelected && e)
          .distinct()
          .listen((_) => update()),
      audioPlayer.stream.currentTrack
          .map((e) => e == track)
          .distinct()
          .listen((_) => update()),
    ];
  }

  @override
  Future<void> dispose() async {
    playAnim.dispose();
    super.dispose();
    await Future.wait(subscriptions.map((e) => e.cancel()));
  }

  void update() {
    setState(() {});
    playAnim.animateTo(isPlaying ? 1 : 0);
  }

  @override
  void didUpdateWidget(covariant TrackLabel oldWidget) {
    playAnim.value = isPlaying ? 1 : 0;
    super.didUpdateWidget(oldWidget);
  }

  Future<void> playPressed() async {
    if (isSelected) {
      if (isPlaying) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }
    } else {
      await audioPlayer.setPlaylist(playlist, index: index, play: true);
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
        padding: const .symmetric(horizontal: 8),
        child: Row(
          spacing: 8,
          children: [
            IconButton(
              onPressed: playPressed,
              icon: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: playAnim,
              ),
              style: ButtonStyle(
                minimumSize: .all(Size.zero),
                iconSize: .all(24),
                padding: .all(.all(4)),
              ),
            ),
            Text(track.title),
            Text(
              track.author,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.inverseSurface.withAlpha(170),
              ),
            ),
            const Expanded(child: SizedBox()),
            if (playlists.isNotEmpty)
              StatefulBuilder(
                builder: (context, setState) => InkWell(
                  customBorder: CircleBorder(),
                  onTap: () async {
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
                  },
                  onSecondaryTap: () {
                    if (mainPlaylist == null) {
                      return;
                    }
                    if (mainPlaylist!.tracks.contains(track)) {
                      setState(() => mainPlaylist!.tracks.remove(track));
                    } else {
                      setState(() => mainPlaylist!.tracks.add(track));
                    }
                  },
                  child: Padding(
                    padding: const .all(6),
                    child: Icon(
                      mainPlaylist?.tracks.contains(track) ??
                              playlists
                                  .where((e) => e.tracks.contains(track))
                                  .isNotEmpty
                          ? Icons.playlist_add_check_rounded
                          : Icons.playlist_add_rounded,
                      size: 20,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                ),
              ),
            Text(
              '${track.duration.inMinutes.toString().padLeft(2, '0')}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  context,
                ).colorScheme.inverseSurface.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> showMenu(BuildContext context, TapDownDetails e) async {
    final controller = OverlayMenuController();
    final availablePlaylists = playlists.where(
      (e) => !e.tracks.contains(track),
    );
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
        if (availablePlaylists.isNotEmpty)
          OverlayMenuItem(
            child: OverlayMenuButton(
              position: .right,
              style: overlayMenuStyle,
              items: availablePlaylists
                  .map(
                    (e) => SimpleMenuItem(
                      text: e.title,
                      onTap: () {
                        e.tracks.add(track);
                        controller.close();
                      },
                    ).toOverlayItem(),
                  )
                  .toList(),
              child: Padding(
                padding: const .symmetric(horizontal: 10),
                child: Text('Добавить в плейлист'),
              ),
            ),
          ),
        if (widget.menuItems != null)
          ...widget.menuItems!.map((e) => e.toOverlayItem()),
      ],
    );
    controller.close();
  }
}
