import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/audio_player/audio_player.dart';
import '../../core/models/track.dart';
import '../simple_menu.dart';
import 'track_list_controller.dart';
import 'widgets/floating_actions_overlay.dart';
import 'widgets/search_field.dart';
import 'widgets/sort_menu_button.dart';
import 'widgets/track_item.dart';

enum Sorting { name, artist, custom, creation }

class TrackList extends StatefulWidget {
  const TrackList(
    this.tracks, {
    required this.onTrackSelected,
    this.sortEnabled = true,
    super.key,
    this.trackMenuItemsBuilder,
  });

  final List<Track> tracks;
  final void Function(int index) onTrackSelected;
  final List<SimpleMenuItem> Function(int index)? trackMenuItemsBuilder;
  final bool sortEnabled;

  @override
  State<TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
  late final TrackListController controller = .new();
  late final StreamSubscription subscription;
  late List<MapEntry<int, Track>> tracks = getTracks();

  var query = '';
  Sorting sort = .custom;

  List<MapEntry<int, Track>> getTracks() {
    final filtered = widget.tracks
        .asMap()
        .entries
        .where(
          (e) =>
              query.isEmpty ||
              e.value.title.toLowerCase().startsWith(query) ||
              e.value.author.toLowerCase().startsWith(query),
        )
        .toList();
    if (widget.sortEnabled && sort != .custom) {
      filtered.sort(
        (a, b) => switch (sort) {
          .name => a.value.title.compareTo(b.value.title),
          .artist => a.value.author.compareTo(b.value.author),
          .creation => -a.value.created.compareTo(b.value.created),
          .custom => 0,
        },
      );
    }
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    controller.tracks = tracks.map((e) => e.value).toList();
    subscription = Stream.periodic(
      const Duration(seconds: 1),
      (_) => widget.tracks.length,
    ).distinct().listen((_) => setState(() {}));
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
    await subscription.cancel();
  }

  void update() {
    tracks = getTracks();
    controller.tracks = tracks.map((e) => e.value).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionsOverlay(
      scrollController: controller,
      tracks: tracks.map((e) => e.value).toList(),
    ),
    body: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SearchField(
                onChanged: (value) {
                  query = value;
                  update();
                  if (audioPlayer.currentTrack != null) {
                    controller.animateToTrack(audioPlayer.currentTrack!);
                  }
                },
                hint: 'Поиск треков',
              ),
            ),
            if (widget.sortEnabled)
              SortMenuButton(
                value: sort,
                onSelected: (e) {
                  sort = e;
                  update();
                  if (audioPlayer.currentTrack != null) {
                    controller.animateToTrack(audioPlayer.currentTrack!);
                  }
                },
              ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemExtent: 50,
            controller: controller,
            itemBuilder: (context, idx) => TrackItem(
              tracks[idx].value,
              onSelected: () => widget.onTrackSelected(tracks[idx].key),
              menuItems: widget.trackMenuItemsBuilder?.call(tracks[idx].key),
              // menuItems: [
              //   SimpleMenuItem(
              //     text: widget.playlist != importedPlaylist
              //         ? 'Удалить из плейлиста'
              //         : 'Удалить песню',
              //     onTap: () => widget.playlist.tracks.remove(tracks[idx]),
              //   ),
              // ],
            ),
          ),
        ),
      ],
    ),
  );
}
