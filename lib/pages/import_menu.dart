import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/services/config_service.dart';

const audioExtensions = ['mp3', 'ogg', 'aac', 'flac', 'midi', 'wav', 'v4a'];

Future<void> _onFilesSelected(List<String> paths) =>
    paths.map(configService.addFile).wait;

Future<void> _onFolderSelected(String path) => configService.addFolder(path);

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
            if (context.mounted) Navigator.pop(context, true);
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
          if (context.mounted) Navigator.pop(context, true);
        },
      ),
    ],
  );

  Widget _buildAdditionsList() => ListView.builder(
    itemCount:
        configService.addedFiles.length + configService.addedFolders.length,
    shrinkWrap: true,
    itemBuilder: (context, index) => _AdditionItem(
      (configService.addedFiles + configService.addedFolders)[index],
      onRemove: () async {
        if (index < configService.addedFiles.length) {
          await configService.removeFile(configService.addedFiles[index]);
        } else {
          await configService.removeFolder(
            configService.addedFolders[index - configService.addedFiles.length],
          );
        }
        setState(() {});
      },
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !selected,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      if (result != true) return;
      Navigator.pop(context);
    },
    child: Center(
      child: Card(
        child: AnimatedSize(
          duration: Durations.medium1,
          curve: Curves.easeInOut,
          child: Padding(
            padding: const .all(40),
            child: !selected
                ? Column(
                    mainAxisSize: .min,
                    spacing: 20,
                    children: [
                      _buildButtonsRow(context),
                      if (configService.addedFiles.isNotEmpty ||
                          configService.addedFolders.isNotEmpty)
                        Flexible(
                          child: SizedBox(
                            width: 270,
                            child: _buildAdditionsList(),
                          ),
                        ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      ),
    ),
  );
}

class _AdditionItem extends StatelessWidget {
  const _AdditionItem(this.title, {required this.onRemove});

  final String title;
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title)),
      IconButton(
        onPressed: onRemove,
        iconSize: 20,
        padding: .zero,
        visualDensity: .compact,
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );
}
