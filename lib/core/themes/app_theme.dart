import 'dart:async';

import 'package:flutter/material.dart';

import '../constants.dart';

class AppTheme {
  final StreamController<ThemeData> _controller = .broadcast();
  late final Stream<ThemeData> stream = _controller.stream.distinct();
  ThemeData _themeData = .new(colorScheme: colorScheme);

  ThemeData get themeData => _themeData;
  set themeData(ThemeData value) {
    _themeData = value;
    _controller.add(value);
  }

  AppTheme._internal();

  static final instance = AppTheme._internal();
}
