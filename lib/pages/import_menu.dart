import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/models/track.dart';
import '../core/services/config_service.dart';

const audioExtensions = ['mp3', 'ogg', 'aac', 'flac', 'midi', 'wav', 'v4a'];

Future<void> _onFilesSelected(List<String> paths) async {
  importedPlaylist.tracks.addAll(
    await Isolate.run(() => paths.map(Track.fromPath)),
  );
}

Future<void> _onFolderSelected(String path) async {
  final folder = Directory(path);
  if (!folder.existsSync()) return;

  importedPlaylist.tracks.addAll(
    await Isolate.run(
      () => folder
          .list()
          .where((e) => audioExtensions.contains(e.path.split('.').last))
          .asyncMap((e) => Track.fromPath(e.path))
          .toList(),
    ),
  );
}

class ImportMenu extends StatefulWidget {
  const ImportMenu({super.key});

  @override
  State<ImportMenu> createState() => _ImportMenuState();
}

class _ImportMenuState extends State<ImportMenu> {
  var selected = false;

  Card _buildButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required void Function() onTap,
  }) => Card(
    color: Theme.of(context).colorScheme.primary.withAlpha(50),
    clipBehavior: .hardEdge,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        height: 120,
        child: Padding(
          padding: const .all(8),
          child: Column(
            spacing: 6,
            mainAxisAlignment: .center,
            mainAxisSize: .min,
            children: [
              Icon(icon, size: 42),
              Text(text, textAlign: .center),
            ],
          ),
        ),
      ),
    ),
  );

  Row _buildButtonsRow(BuildContext context) => Row(
    mainAxisSize: .min,
    spacing: 20,
    children: [
      _buildButton(
        context,
        icon: Icons.file_copy_rounded,
        text: 'Добавить файлы',
        onTap: () async {
          final result = await FilePicker.pickFiles(
            type: .custom,
            dialogTitle: 'Flux Import Files',
            allowedExtensions: audioExtensions,
            allowMultiple: true,
          );
          if (result != null) {
            setState(() => selected = true);
            await _onFilesSelected(
              result.files.map((e) => e.path).nonNulls.toList(),
            );
            if (context.mounted) Navigator.pop(context);
          }
        },
      ),
      _buildButton(
        context,
        icon: Icons.folder_copy_rounded,
        text: 'Добавить папки',
        onTap: () async {
          final result = await FilePicker.getDirectoryPath(
            dialogTitle: 'Flux Import Folder',
          );
          if (result == null) return;

          setState(() => selected = true);
          await _onFolderSelected(result);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      child: AnimatedSize(
        duration: Durations.medium1,
        curve: Curves.easeInOut,
        child: Padding(
          padding: const .all(40),
          child: !selected
              ? _buildButtonsRow(context)
              : const CircularProgressIndicator(),
        ),
      ),
    ),
  );
}
