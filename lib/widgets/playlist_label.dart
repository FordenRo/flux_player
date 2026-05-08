import 'package:flutter/material.dart';

import '../audio_player.dart';
import '../config.dart';
import '../utils/simple_menu.dart';

class PlaylistLabel extends StatefulWidget {
  const PlaylistLabel(this.playlist, {super.key, this.onTap});

  final Playlist playlist;
  final void Function()? onTap;

  @override
  State<PlaylistLabel> createState() => _PlaylistLabelState();
}

class _PlaylistLabelState extends State<PlaylistLabel> {
  late final TextEditingController controller = .new(text: playlist.title);
  late final FocusNode focusNode = .new()..addListener(() => setState(() {}));

  Playlist get playlist => widget.playlist;
  Duration get overallDuration =>
      playlist.tracks.fold(Duration.zero, (prev, e) => prev + e.duration);

  var iconHovered = false;

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: .hardEdge,
    child: GestureDetector(
      onTap: !focusNode.hasFocus ? widget.onTap : null,
      behavior: .opaque,
      onSecondaryTapDown: (e) => showMenu(context, e),
      child: Padding(
        padding: const .all(10),
        child: Row(
          spacing: 20,
          children: [
            buildIcon(),
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: TextField(
                      selectAllOnFocus: true,
                      ignorePointers: !focusNode.hasFocus,
                      focusNode: focusNode,
                      mouseCursor: WidgetStateMouseCursor.fromMap({
                        WidgetState.focused: SystemMouseCursors.text,
                        WidgetState.any: .defer,
                      }),
                      onEditingComplete: () => playlist.title = controller.text,
                      controller: controller,
                      style: .new(fontSize: 18),
                      decoration: .new(hintText: 'Название', border: .none),
                    ),
                  ),
                  Align(
                    alignment: .bottomLeft,
                    child: Text(
                      '${playlist.tracks.length} треков',
                      style: .new(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ),
                  Align(
                    alignment: .bottomRight,
                    child: Text(
                      overallDuration.inMinutes > 100
                          ? '${(overallDuration.inMinutes / 60).toStringAsFixed(1)} часов'
                          : '${overallDuration.inMinutes} минут',
                      style: .new(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        StatefulBuilder(
          builder: (context, setState) => MouseRegion(
            onEnter: (_) => setState(() => iconHovered = true),
            onExit: (_) => setState(() => iconHovered = false),
            child: AnimatedOpacity(
              opacity: iconHovered ? 1 : 0,
              duration: Durations.short2,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface.withAlpha(100),
                child: Center(
                  child: IconButton(
                    onPressed: () =>
                        audioPlayer.setPlaylist(playlist, index: 0, play: true),
                    iconSize: 32,
                    icon: Icon(Icons.play_arrow_rounded),
                  ),
                ),
              ),
            ),
          ),
        ),
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
