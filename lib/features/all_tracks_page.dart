import 'package:flutter/material.dart';

import '../core/config.dart';
import '../widgets/track_list/track_list.dart';

class AllTracksPage extends StatefulWidget {
  const AllTracksPage({super.key});

  @override
  State<AllTracksPage> createState() => _AllTracksPageState();
}

class _AllTracksPageState extends State<AllTracksPage> {
  @override
  Widget build(BuildContext context) => TrackList(playlist: importedPlaylist);
}
