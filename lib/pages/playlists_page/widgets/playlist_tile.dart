import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/audio_player/audio_player.dart';
import '../../../core/constants.dart';
import '../../../core/models/playlist.dart';
import '../../../core/services/config_service.dart';
import '../../../widgets/simple_menu.dart';

class PlaylistTile extends StatefulWidget {
  const PlaylistTile(this.playlist, {super.key, this.onTap});

  final Playlist playlist;
  final void Function()? onTap;

  @override
  State<PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<PlaylistTile> {
  late final TextEditingController controller = .new(text: playlist.title);
  late final FocusNode focusNode = .new()..addListener(() => setState(() {}));
  late final StreamSubscription playlistSub;

  Playlist get playlist => widget.playlist;
  Duration get overallDuration =>
      playlist.tracks.fold(Duration.zero, (prev, e) => prev + e.duration);

  var iconHovered = false;

  @override
  void initState() {
    super.initState();
    playlistSub = audioPlayer.stream.currentPlaylist.listen(
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    playlistSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: .hardEdge,
    shape: RoundedRectangleBorder(
      borderRadius: .circular(12),
      side: audioPlayer.currentPlaylist == playlist
          ? .new(color: colorScheme.primary)
          : .none,
    ),
    child: GestureDetector(
      onTap: !focusNode.hasFocus ? widget.onTap : null,
      behavior: .opaque,
      onSecondaryTapDown: (e) => showMenu(context, e),
      child: Padding(
        padding: const .all(10),
        child: Row(spacing: 20, children: [buildIcon(), buildInfo()]),
      ),
    ),
  );

  Expanded buildInfo() => Expanded(
    child: Stack(
      children: [
        Center(
          child: TextField(
            selectAllOnFocus: true,
            ignorePointers: !focusNode.hasFocus,
            focusNode: focusNode,
            mouseCursor: const WidgetStateMouseCursor.fromMap({
              WidgetState.focused: SystemMouseCursors.text,
              WidgetState.any: .defer,
            }),
            onEditingComplete: () => playlist.title = controller.text,
            controller: controller,
            style: const .new(fontSize: 18),
            decoration: const .new(hintText: 'Название', border: .none),
          ),
        ),
        Align(
          alignment: .bottomLeft,
          child: Text(
            '${playlist.tracks.length} треков',
            style: .new(color: colorScheme.onSurface.withAlpha(180)),
          ),
        ),
        Align(
          alignment: .bottomRight,
          child: Text(
            overallDuration.inMinutes > 100
                ? '${(overallDuration.inMinutes / 60).toStringAsFixed(1)} часов'
                : '${overallDuration.inMinutes} минут',
            style: .new(color: colorScheme.onSurface.withAlpha(180)),
          ),
        ),
        if (mainPlaylist == playlist)
          Align(
            alignment: .topRight,
            child: Icon(Icons.star_rounded, color: colorScheme.tertiary),
          ),
      ],
    ),
  );

  Container buildIcon() => Container(
    width: 80,
    height: 80,
    clipBehavior: .hardEdge,
    decoration: BoxDecoration(
      borderRadius: .circular(8),
      border: .all(strokeAlign: 1, width: 1, color: Colors.grey.shade600),
    ),
    child: Stack(
      fit: .expand,
      children: [
        GridView.count(
          primary: false,
          scrollDirection: .horizontal,
          crossAxisCount: 2,
          clipBehavior: .none,
          children: playlist.tracks
              .where((e) => e.picture != null)
              .take(4)
              .map((e) => Image.memory(e.picture!.bytes))
              .toList(),
        ),
        _PlayButton(playlist),
      ],
    ),
  );

  Future<void> showMenu(BuildContext context, TapDownDetails e) =>
      showSimpleMenu(
        context: context,
        offset: e.localPosition.translate(0, -context.size!.height),
        items: [
          SimpleMenuItem(text: 'Переименовать', onTap: focusNode.requestFocus),
          if (mainPlaylist != playlist)
            SimpleMenuItem(
              text: 'Сделать главным',
              onTap: () => mainPlaylist = playlist,
            ),
          SimpleMenuItem(
            text: 'Удалить',
            onTap: () => playlists.remove(playlist),
          ),
        ],
      );
}

class _PlayButton extends StatefulWidget {
  const _PlayButton(this.playlist);

  final Playlist playlist;

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
  late final StreamSubscription isPlayingSub;
  late final StreamSubscription playlistSub;
  var isHovered = false;

  Playlist get playlist => widget.playlist;
  bool get isSelected => audioPlayer.currentPlaylist == playlist;
  bool get isPlaying => isSelected && audioPlayer.isPlaying;
  bool get isVisible => isHovered || isPlaying;

  Future<void> playPressed() async {
    if (isSelected) {
      if (isPlaying) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }
    } else {
      await audioPlayer.setPlaylist(playlist, index: 0, play: true);
    }
  }

  @override
  void initState() {
    super.initState();
    isPlayingSub = audioPlayer.stream.isPlaying
        .where((_) => playlist == audioPlayer.currentPlaylist)
        .listen((_) => update());
    playlistSub = audioPlayer.stream.currentPlaylist.listen((_) => update());
  }

  @override
  void dispose() {
    isPlayingSub.cancel();
    playlistSub.cancel();
    super.dispose();
  }

  void update() {
    setState(() {});
    playAnim.animateTo(isPlaying ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => isHovered = true),
    onExit: (_) => setState(() => isHovered = false),
    child: AnimatedOpacity(
      opacity: isVisible ? 1 : 0,
      duration: Durations.short2,
      child: ColoredBox(
        color: colorScheme.surface.withAlpha(100),
        child: Center(
          child: IconButton(
            onPressed: playPressed,
            iconSize: 32,
            icon: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: playAnim,
            ),
          ),
        ),
      ),
    ),
  );
}
