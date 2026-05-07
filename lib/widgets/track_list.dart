import 'dart:async';

import 'package:flutter/material.dart';

import '../audio_player.dart';
import '../config.dart';
import 'overlay_menu.dart';
import 'track_label.dart';
import 'track_list/floating_actions_overlay.dart';
import 'track_list/search_field.dart';
import 'track_list/sort_menu_button.dart';
import 'track_list/track_list_controller.dart';

enum Sorting { name, artist, dateAdded, lastPlayed, playCount }

class TrackList extends StatefulWidget {
  final Playlist playlist;

  const TrackList({super.key, required this.playlist});

  @override
  State<TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
  late final TrackListController controller = .new(tracks);
  late final StreamSubscription subscription;
  late var tracks = getTracks();

  var query = '';
  Sorting sort = .dateAdded;

  List<AudioTrack> getTracks() =>
      widget.playlist.tracks
          .where(
            (e) =>
                query.isEmpty ||
                e.title.toLowerCase().startsWith(query) ||
                e.author.toLowerCase().startsWith(query),
          )
          .toList()
        ..sort(
          (a, b) => switch (sort) {
            .name => a.title.compareTo(b.title),
            .artist => a.author.compareTo(b.author),
            _ => a.title.compareTo(b.title),
          },
        );

  @override
  void initState() {
    super.initState();
    subscription = Stream.periodic(
      const Duration(seconds: 1),
      (_) => widget.playlist.tracks.length,
    ).distinct().listen((_) => setState(() {}));
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    tracks = getTracks();
    controller.tracks = tracks;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
    await subscription.cancel();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionsOverlay(
      scrollController: controller,
      tracks: tracks,
    ),
    body: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SearchField(
                onChanged: (value) {
                  setState(() => query = value);
                  if (audioPlayer.currentTrack != null) {
                    controller.animateToTrack(audioPlayer.currentTrack!);
                  }
                },
                hint: 'Search',
              ),
            ),
            SortMenuButton(
              onSelected: (e) {
                setState(() => sort = e);
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
            itemBuilder: (context, idx) => TrackLabel(
              tracks,
              idx,
              menuItems: [
                SimpleMenuItem(
                  text: widget.playlist != importedPlaylist
                      ? 'Удалить из плейлиста'
                      : 'Удалить песню',
                  onTap: () => widget.playlist.tracks.remove(tracks[idx]),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
