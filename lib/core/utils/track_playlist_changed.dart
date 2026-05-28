import 'dart:async';

import '../models/track.dart';

final StreamController<Track> trackPlaylistChanged = .broadcast();
