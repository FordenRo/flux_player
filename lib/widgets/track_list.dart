import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';

import '../audio_player.dart';
import 'track_label.dart';

class TrackList extends StatefulWidget {
  final List<AudioTrack> tracks;

  const TrackList({super.key, required this.tracks});

  @override
  State<TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
  late final ScrollController controller = .new();

  var query = '';
  Sorting sort = .dateAdded;

  List<AudioTrack> get tracks =>
      widget.tracks
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
  void dispose() {
    controller.dispose();
    super.dispose();
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
                onChanged: (value) => setState(() => query = value),
                hint: 'Search',
              ),
            ),
            SortMenuButton(onSelected: (e) => setState(() => sort = e)),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemExtent: 50,
            controller: controller,
            itemBuilder: (context, idx) => TrackLabel(tracks, idx),
          ),
        ),
      ],
    ),
  );
}

enum Sorting { name, artist, dateAdded, lastPlayed, playCount }

class SortMenuButton extends StatelessWidget {
  final void Function(Sorting sort) onSelected;

  const SortMenuButton({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) => OverlayMenuButton(
    alignment: .center,
    style: .new(padding: .zero, itemStyle: .new(height: 30)),
    onSelected: onSelected,
    items: [
      _buildItem('Name', Sorting.name),
      _buildItem('Artist', Sorting.artist),
      _buildItem('Date added', Sorting.dateAdded),
      _buildItem('Last played', Sorting.lastPlayed),
      _buildItem('Play count', Sorting.playCount),
    ],
    child: Padding(
      padding: const .symmetric(horizontal: 10, vertical: 5),
      child: Row(
        spacing: 8,
        children: [
          SizedBox(),
          Text('Name', style: .new(color: Colors.grey.shade500)),
          Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade500),
        ],
      ),
    ),
  );

  OverlayMenuItem<T> _buildItem<T>(String text, T value) => OverlayMenuItem<T>(
    value: value,
    child: Padding(padding: const .symmetric(horizontal: 8), child: Text(text)),
  );
}

class SearchField extends StatefulWidget {
  final void Function(String query) onChanged;
  final String hint;

  const SearchField({super.key, required this.onChanged, required this.hint});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(horizontal: 18),
    child: TextField(
      controller: controller,
      onChanged: widget.onChanged,
      style: .new(fontSize: 14),
      decoration: .new(
        icon: Icon(Icons.search, color: Colors.grey.shade600, size: 18),
        hintText: widget.hint,
        hintStyle: .new(color: Colors.grey.shade500),
        border: .none,
        isDense: true,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 20, color: Colors.grey.shade600),
                onPressed: () {
                  controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        contentPadding: .symmetric(vertical: 12),
      ),
    ),
  );
}

class FloatingActionsOverlay extends StatefulWidget {
  final ScrollController scrollController;
  final List<AudioTrack> tracks;

  const FloatingActionsOverlay({
    super.key,
    required this.scrollController,
    required this.tracks,
  });

  @override
  State<FloatingActionsOverlay> createState() => _FloatingActionsOverlayState();
}

class _FloatingActionsOverlayState extends State<FloatingActionsOverlay> {
  ScrollController get controller => widget.scrollController;
  int? get currentTrackPos => audioPlayer.currentTrack != null
      ? (widget.tracks.indexOf(audioPlayer.currentTrack!) - 1) * 50
      : null;

  late bool showWatchTrack = canShowWatchTrack();
  late bool showGoTop = canShowGoTop();
  late final StreamSubscription subscription;

  var watchCurrentTrack = false;

  bool canShowWatchTrack() =>
      currentTrackPos != null &&
      !watchCurrentTrack &&
      (currentTrackPos! - controller.offset).abs() > 80;

  bool canShowGoTop() => controller.offset > 1000;

  @override
  void initState() {
    super.initState();

    controller.position.addListener(update);
    subscription = audioPlayer.stream.currentIndex.listen((_) {
      if (watchCurrentTrack) {
        animateToTrack();
      } else {
        update();
      }
    });
  }

  void update() {
    if (watchCurrentTrack && controller.position.userScrollDirection != .idle) {
      watchCurrentTrack = false;
    }
    var canShowWatch = canShowWatchTrack();
    var canShowTop = canShowGoTop();
    if (canShowWatch != showWatchTrack || canShowTop != showGoTop) {
      setState(() {
        showWatchTrack = canShowWatch;
        showGoTop = canShowTop;
      });
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await subscription.cancel();
  }

  Future<void> animateToTrack() => controller.animateTo(
    currentTrackPos!.toDouble(),
    duration: Durations.long2,
    curve: Curves.easeOutQuart,
  );

  Future<void> animateToTop() => controller.animateTo(
    0,
    duration: Durations.extralong1,
    curve: Curves.easeOutQuart,
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    spacing: 4,
    children: [
      AnimatedSlide(
        offset: Offset(0, showWatchTrack ? 0 : 1.4),
        duration: Durations.medium1,
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: showGoTop ? 1 : 0,
          duration: Durations.medium1,
          child: IconButton.filled(
            onPressed: animateToTop,
            iconSize: 20,
            padding: .zero,
            splashRadius: 10,
            visualDensity: .compact,
            style: .new(
              backgroundColor: .all(
                Color.alphaBlend(
                  Theme.of(context).colorScheme.secondary.withAlpha(100),
                  Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
            color: Theme.of(context).colorScheme.onSurface,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ),
      ),
      AnimatedOpacity(
        opacity: showWatchTrack ? 1 : 0,
        duration: Durations.medium1,
        child: IconButton.filled(
          onPressed: () {
            showWatchTrack ? animateToTrack() : animateToTop();
            watchCurrentTrack = showWatchTrack;
          },
          iconSize: 22,
          padding: .zero,
          splashRadius: 10,
          visualDensity: .comfortable,
          style: .new(
            backgroundColor: .all(
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withAlpha(120),
                Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          color: Theme.of(context).colorScheme.onSurface,
          icon: const Icon(Icons.music_note_rounded),
        ),
      ),
    ],
  );
}
