import 'dart:async';

import 'package:flutter/material.dart';

import '../audio_player.dart';
import '../widgets/track_list.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: Stream.periodic(
      const Duration(seconds: 1),
      (_) => importedTracks.length,
    ).distinct(),
    builder: (context, asyncSnapshot) => TrackList(tracks: importedTracks),
  );
}
