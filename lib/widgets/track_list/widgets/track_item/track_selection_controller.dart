import 'package:flutter/material.dart';
import '../../../../core/models/track.dart';

class TrackSelectionController extends ChangeNotifier {
  final Set<Track> _selectedTracks = {};

  Set<Track> get selectedTracks => _selectedTracks;
  bool get isEmpty => selectedTracks.isEmpty;
  bool get isNotEmpty => selectedTracks.isNotEmpty;

  void add(Track track) {
    _selectedTracks.add(track);
    notifyListeners();
  }

  void addAll(List<Track> tracks) {
    _selectedTracks.addAll(tracks);
    notifyListeners();
  }

  void remove(Track track) {
    _selectedTracks.remove(track);
    notifyListeners();
  }

  bool hasSelection(Track track) => selectedTracks.contains(track);

  void clear() {
    _selectedTracks.clear();
    notifyListeners();
  }
}
