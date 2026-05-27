import 'package:flutter/material.dart';

import '../core/services/config_service.dart';
import '../core/theme/theme.dart';

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
          children: seedColors.map(_ColorButton.new).toList(),
        ),
      ),
      ListTile(
        title: const Text('Dark theme'),
        trailing: StatefulBuilder(
          builder: (context, setState) => Checkbox(
            value: appTheme.brightness == .dark,
            onChanged: (value) =>
                setState(() => appTheme.brightness = value! ? .dark : .light),
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
          onPressed: importedPlaylist.clear,
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
    onTap: () => appTheme.seedColor = color,
    child: Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: Radiuses.r8,
        color: color,
        border: .all(color: Colors.grey.shade400, strokeAlign: 1, width: 1),
      ),
    ),
  );
}
