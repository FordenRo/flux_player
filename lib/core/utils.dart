import 'dart:async';

final StreamController trackPlaylistChanged = .broadcast();

extension MoveElement<T> on List<T> {
  void move(int index, int newIndex) {
    final element = this[index];
    removeAt(index);
    insert(newIndex, element);
  }
}
