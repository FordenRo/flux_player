import 'package:flutter/material.dart';

import '../music_controller.dart';
import '../widgets/track_label.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  var query = '';

  Iterable<MapEntry<int, AudioTrack>> get tracks =>
      audioPlayer.audioTracks.asMap().entries.where(
        (e) =>
            query.isEmpty ||
            e.value.title.toLowerCase().contains(query) ||
            e.value.author.toLowerCase().contains(query),
      );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .max,
    children: [
      SearchField(
        hint: 'Поиск музыки',
        onChanged: (v) => setState(() => query = v.toLowerCase()),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, idx) => TrackLabel(tracks.elementAt(idx).key),
        ),
      ),
    ],
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
