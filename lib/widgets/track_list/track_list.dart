import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/audio_player/audio_player.dart';
import '../../core/audio_player/track.dart';
import '../../core/config.dart';
import '../../core/audio_player/playlist.dart';
import '../../features/simple_menu.dart';
import '../track_label.dart';
import 'floating_actions_overlay.dart';
import 'search_field.dart';
import 'sort_menu_button.dart';
import 'track_list_controller.dart';

enum Sorting { name, artist, dateAdded, lastPlayed, playCount }

class TrackList extends StatefulWidget {
  final Playlist playlist;

  const TrackList({super.key, required this.playlist});

  @override
  State<TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
  late final TrackListController controller = .new();
  late final StreamSubscription subscription;

  var query = '';
  Sorting _sort = .name;

  Sorting get sort => _sort;

  set sort(Sorting value) {
    _sort = value;
    widget.playlist.tracks.sort(
      (a, b) => switch (sort) {
        .name => a.title.compareTo(b.title),
        .artist => a.author.compareTo(b.author),
        _ => a.title.compareTo(b.title),
      },
    );
  }

  List<Track> getTracks() => widget.playlist.tracks
      .where(
        (e) =>
            query.isEmpty ||
            e.title.toLowerCase().startsWith(query) ||
            e.author.toLowerCase().startsWith(query),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    subscription = Stream.periodic(
      const Duration(seconds: 1),
      (_) => widget.playlist.tracks.length,
    ).distinct().listen((_) => setState(() {}));
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
    await subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final tracks = getTracks();
    controller.tracks = tracks;
    return Scaffold(
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
                widget.playlist,
                widget.playlist.tracks.indexOf(tracks[idx]),
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
}
