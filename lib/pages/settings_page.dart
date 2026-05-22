import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../core/constants.dart';
import '../core/services/config_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      ListTile(
        title: const Text('Theme color'),
        trailing: Row(
          spacing: 8,
          mainAxisSize: .min,
          children: themeColors.map(_ColorButton.new).toList(),
        ),
      ),
      ListTile(
        title: const Text('Dark theme'),
        trailing: StatefulBuilder(
          builder: (context, setState) => Checkbox(
            value: appController.isThemeDark,
            onChanged: (value) =>
                setState(() => appController.isThemeDark = value!),
          ),
        ),
      ),
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

class _ColorButton extends StatelessWidget {
  const _ColorButton(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => appController.themePrimaryColor = color,
    child: Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: .circular(8),
        color: color,
        border: .all(color: Colors.grey.shade400, strokeAlign: 1, width: 1),
      ),
    ),
  );
}
