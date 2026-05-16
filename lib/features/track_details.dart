import 'dart:io';

import 'package:flutter/material.dart';

import '../core/audio_player/track.dart';
import '../core/constants.dart';

final TextStyle _keyStyle = .new(
  color: colorScheme.onSurface.withAlpha(200),
  fontSize: 12,
);
const TextStyle _valueStyle = .new(fontSize: 14);

class TrackDetails extends StatelessWidget {
  const TrackDetails(this.track, {super.key});
  final Track track;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const .all(100),
      child: Card(
        child: Padding(
          padding: const .all(8),
          child: SingleChildScrollView(
            padding: const .all(10),
            child: Column(
              children: [
                const Text('Свойства\n'),
                _buildDetailsText(),
                TextButton(
                  onPressed: () =>
                      Process.run('explorer', ['/select,', track.path]),
                  child: const Text('Открыть папку с файлом'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  RichText _buildDetailsText() {
    final fields = {
      'Название': track.metadata.title,
      'Исполнители': track.metadata.artist?.split('/').join('\n'),
      'Альбом': track.metadata.album,
      'Жанры': track.metadata.genres.join('\n'),
      'Год': track.metadata.year?.year,
      'Поток': track.metadata.bitrate != null
          ? '${track.metadata.bitrate! ~/ 1000} кбит/c'
          : null,
      'Путь': track.path,
    };

    return RichText(
      text: TextSpan(
        children: fields.entries
            .where((e) => e.value != null)
            .map(
              (e) => TextSpan(
                children: [
                  TextSpan(text: '${e.key}\n', style: _keyStyle),
                  TextSpan(text: '${e.value}\n\n', style: _valueStyle),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
