import 'package:flutter/material.dart';

import '../core/config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      ListTile(
        title: const Text('Delete all playlists'),
        trailing: IconButton(
          onPressed: playlists.clear,
          icon: const Icon(Icons.delete_outlined),
        ),
      ),
      ListTile(
        title: const Text('Delete all imports'),
        trailing: IconButton(
          onPressed: importedPlaylist.tracks.clear,
          icon: const Icon(Icons.delete_outlined),
        ),
      ),
    ],
  );
}
