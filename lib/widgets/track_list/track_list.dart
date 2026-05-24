import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/track.dart';
import '../simple_menu.dart';
import 'track_list_controller.dart';
import 'widgets/floating_actions_overlay.dart';
import 'widgets/search_field.dart';
import 'widgets/sort_menu_button.dart';
import 'widgets/track_item/track_item.dart';
import 'widgets/track_item/track_selection_controller.dart';

enum Sorting { name, artist, custom, creation }

class TrackList extends StatefulWidget {
  const TrackList(
    this.tracks, {
    required this.onTrackSelected,
    this.onTrackMoved,
    this.sortEnabled = true,
    this.selectionEnabled = true,
    this.trackMenuItemsBuilder,
    this.selectionController,
    super.key,
  });

  final List<Track> tracks;
  final void Function(int index) onTrackSelected;
  final void Function(int oldIndex, int newIndex)? onTrackMoved;
  final List<SimpleMenuItem> Function(int index)? trackMenuItemsBuilder;
  final bool sortEnabled;
  final bool selectionEnabled;
  final TrackSelectionController? selectionController;

  @override
  State<TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
  final TrackListController controller = .new();
  late final TrackSelectionController? selectionController =
      widget.selectionEnabled ? (widget.selectionController ?? .new()) : null;
  late final StreamSubscription subscription;
  late List<MapEntry<int, Track>> tracks = _getTracks();

  var query = '';
  Set<int> selectedTracks = {};
  Sorting sort = .custom;

  bool get isReorderable => widget.onTrackMoved != null && sort == .custom;

  List<MapEntry<int, Track>> _getTracks() {
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
    selectionController?.addListener(_onSelectionUpdate);
  }

  @override
  void dispose() {
    selectionController?.removeListener(_onSelectionUpdate);
    controller.dispose();
    subscription.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TrackList oldWidget) {
    super.didUpdateWidget(oldWidget);
    tracks = _getTracks();
    controller.tracks = tracks.map((e) => e.value).toList();
  }

  void _onSelectionUpdate() => setState(() {});

  void _update() {
    tracks = _getTracks();
    controller.tracks = tracks.map((e) => e.value).toList();
    setState(() {});
  }

  ListView _buildList() => ListView.builder(
    itemCount: tracks.length,
    itemExtent: 50,
    controller: controller,
    itemBuilder: (context, idx) => _buildItem(idx),
  );

  TrackItem _buildItem(int idx) => TrackItem(
    tracks[idx].value,
    selectionController: selectionController,
    onPlay: () => widget.onTrackSelected(tracks[idx].key),
    menuItems: selectedTracks.isEmpty
        ? widget.trackMenuItemsBuilder?.call(tracks[idx].key)
        : [],
  );

  ReorderableListView _buildReorderableList() => ReorderableListView.builder(
    itemCount: tracks.length,
    itemExtent: 50,
    buildDefaultDragHandles: false,
    scrollController: controller,
    onReorder: widget.onTrackMoved!,
    itemBuilder: (context, idx) => ReorderableDragStartListener(
      key: Key(idx.toString()),
      index: idx,
      child: _buildItem(idx),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionsOverlay(
      listController: controller,
      tracks: tracks.map((e) => e.value).toList(),
    ),
    body: Column(
      children: [
        Row(
          children: [
            if (selectionController?.selectedTracks.isNotEmpty ?? false)
              Checkbox(
                value:
                    selectionController!.selectedTracks.length == tracks.length,
                onChanged: (value) => !value!
                    ? selectionController!.clear()
                    : selectionController!.addAll(
                        tracks.map((e) => e.value).toList(),
                      ),
              ),
            Expanded(
              child: SearchField(
                onChanged: (value) {
                  query = value;
                  _update();
                  controller.animateToCurrentTrack();
                },
                hint: 'Поиск треков',
              ),
            ),
            if (widget.sortEnabled)
              SortMenuButton(
                value: sort,
                onSelected: (e) {
                  sort = e;
                  _update();
                  controller.animateToCurrentTrack();
                },
              ),
          ],
        ),
        Expanded(child: isReorderable ? _buildReorderableList() : _buildList()),
      ],
    ),
  );
}
