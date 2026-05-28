import 'package:audio_service/audio_service.dart' show MediaItem;
import '../models/track.dart';

extension MediaItemAdapter on Track {
  MediaItem toMediaItem() => MediaItem(
    id: 'testid',
    title: title,
    album: '',
    artist: author,
    duration: duration,
  );
}
