import 'dart:async';

import 'package:flutter/material.dart';

import '../audio_player.dart';
import '../widgets/track_label.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  var query = '';
  late final ScrollController controller = .new(
    onAttach: (position) => position.addListener(
      () => floatingUpdater.add(
        (controller.offset > 1000) ^
            (currentTrackPos != null &&
                (currentTrackPos! - controller.offset).abs() > 500),
      ),
    ),
  );
  final StreamController<bool?> floatingUpdater = .broadcast();
  late final floatingStream = floatingUpdater.stream.distinct();
  late final StreamSubscription indexSubscription;

  List<AudioTrack> get filteredTracks => importedTracks
      .where(
        (e) =>
            query.isEmpty ||
            e.title.toLowerCase().startsWith(query) ||
            e.author.toLowerCase().startsWith(query),
      )
      .toList();

  int? get currentTrackPos => audioPlayer.currentTrack != null
      ? (filteredTracks.indexOf(audioPlayer.currentTrack!) - 1) * 50
      : null;
  bool get showTop =>
      currentTrackPos != null &&
      (currentTrackPos! - controller.offset).abs() > 500;

  @override
  void initState() {
    super.initState();

    indexSubscription = audioPlayer.stream.currentIndex.listen(
      (_) => floatingUpdater.add(null),
    );
  }

  @override
  Future<void> dispose() async {
    controller.dispose();
    super.dispose();
    await floatingUpdater.close();
    await indexSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FutureBuilder(
      future: Future.doWhile(
        () => Future.delayed(Durations.short1, () => !controller.hasClients),
      ),
      builder: (context, asyncSnapshot) =>
          asyncSnapshot.connectionState == .done
          ? StreamBuilder(
              stream: floatingStream,
              builder: (context, snapshot) => Column(
                spacing: 4,
                mainAxisSize: .min,
                children: [
                  AnimatedSlide(
                    offset: Offset(0, showTop ? 0 : 1.4),
                    duration: Durations.medium1,
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: controller.offset > 1000 ? 1 : 0,
                      duration: Durations.medium1,
                      child: IconButton.filled(
                        onPressed: () => controller.animateTo(
                          0,
                          duration: Durations.extralong1,
                          curve: Curves.easeOutQuart,
                        ),
                        iconSize: 20,
                        padding: .zero,
                        splashRadius: 10,
                        visualDensity: .compact,
                        style: .new(
                          backgroundColor: .all(
                            Color.alphaBlend(
                              Theme.of(
                                context,
                              ).colorScheme.secondary.withAlpha(100),
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
                    opacity: showTop ? 1 : 0,
                    duration: Durations.medium1,
                    child: IconButton.filled(
                      onPressed: () => showTop
                          ? controller.animateTo(
                              currentTrackPos!.toDouble(),
                              duration: Durations.long2,
                              curve: Curves.easeOutQuart,
                            )
                          : controller.animateTo(
                              0,
                              duration: Durations.extralong1,
                              curve: Curves.easeOutQuart,
                            ),
                      iconSize: 22,
                      padding: .zero,
                      splashRadius: 10,
                      visualDensity: .comfortable,
                      style: .new(
                        backgroundColor: .all(
                          Color.alphaBlend(
                            Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(120),
                            Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                      color: Theme.of(context).colorScheme.onSurface,
                      icon: const Icon(Icons.music_note_rounded),
                    ),
                  ),
                ],
              ),
            )
          : SizedBox(),
    ),
    body: Column(
      mainAxisSize: .max,
      children: [
        SearchField(
          hint: 'Поиск музыки',
          onChanged: (v) => setState(() => query = v.toLowerCase()),
        ),
        Expanded(
          child: StreamBuilder(
            stream: Stream.periodic(
              const Duration(seconds: 1),
              (_) => importedTracks.length,
            ).distinct(),
            builder: (context, asyncSnapshot) => ListView.builder(
              itemExtent: 50,
              controller: controller,
              itemCount: filteredTracks.length,
              itemBuilder: (context, idx) => TrackLabel(
                filteredTracks,
                idx,
                removeFrom: (track) => importedTracks.remove(track),
              ),
            ),
          ),
        ),
      ],
    ),
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
  Widget build(BuildContext context) => Card(
    margin: const .only(bottom: 16),
    child: Padding(
      padding: const .symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey.shade600),
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: .none,
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          contentPadding: const .symmetric(vertical: 14),
        ),
      ),
    ),
  );
}
