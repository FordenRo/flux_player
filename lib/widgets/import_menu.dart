import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../music_controller.dart';

const audioExtensions = ['mp3', 'ogg', 'aac', 'flac', 'midi', 'wav', 'v4a'];

Future<void> _onFilesSelected(List<String> paths) async =>
    importedTracks.addAll(
      await Stream.fromIterable(paths).asyncMap(AudioTrack.fromPath).toList(),
    );

Future<void> _onFolderSelected(String path) async {
  final folder = Directory(path);
  if (!await folder.exists()) {
    return;
  }
  importedTracks.addAll(
    await folder
        .list()
        .where((e) => audioExtensions.contains(e.path.split('.').last))
        .asyncMap((e) => AudioTrack.fromPath(e.path))
        .toList(),
  );
}

class ImportMenu extends StatelessWidget {
  const ImportMenu({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      child: Padding(
        padding: const .all(40),
        child: Row(
          mainAxisSize: .min,
          spacing: 20,
          children: [
            buildButton(
              context,
              icon: Icons.file_copy_rounded,
              text: 'Add files',
              onTap: () async {
                var result = await FilePicker.pickFiles(
                  type: .custom,
                  dialogTitle: 'Flux Import Files',
                  allowedExtensions: audioExtensions,
                  allowMultiple: true,
                );
                if (result != null) {
                  await _onFilesSelected(
                    result.files.map((e) => e.path).nonNulls.toList(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
            buildButton(
              context,
              icon: Icons.folder_copy_rounded,
              text: 'Add folder',
              onTap: () async {
                var result = await FilePicker.getDirectoryPath(
                  dialogTitle: 'Flux Import Folder',
                );
                if (result != null) {
                  await _onFolderSelected(result);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
      ),
    ),
  );

  Card buildButton(
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
        width: 100,
        height: 100,
        child: Column(
          spacing: 6,
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [Icon(icon, size: 42), Text(text)],
        ),
      ),
    ),
  );
}
