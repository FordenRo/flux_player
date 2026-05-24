import 'package:flutter/material.dart';

const List<Color> seedColors = [
  Colors.red,
  Colors.green,
  Colors.pink,
  Colors.purple,
  Colors.blue,
  Colors.yellow,
];

abstract final class Radiuses {
  static const BorderRadius r6 = .all(.circular(6));
  static const BorderRadius r8 = .all(.circular(8));
  static const BorderRadius r12 = .all(.circular(12));
}
