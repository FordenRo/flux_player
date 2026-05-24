import 'package:flutter/material.dart';

import 'src/values.dart';

export 'src/styles.dart';
export 'src/values.dart';

final appTheme = AppTheme._();

class AppTheme with ChangeNotifier {
  AppTheme._();

  late ThemeData _themeData = _getThemeData(
    seedColor: seedColor,
    brightness: .dark,
  );
  Color _seedColor = seedColors.first;
  Brightness _brightness = .dark;

  ThemeData get themeData => _themeData;
  Color get seedColor => _seedColor;
  Brightness get brightness => _brightness;

  set seedColor(Color value) {
    _seedColor = value;
    _themeData = _getThemeData(seedColor: seedColor, brightness: brightness);
    notifyListeners();
  }

  set brightness(Brightness value) {
    _brightness = value;
    _themeData = _getThemeData(seedColor: seedColor, brightness: brightness);
    notifyListeners();
  }
}

ThemeData _getThemeData({
  required Color seedColor,
  required Brightness brightness,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  return .new(
    colorScheme: colorScheme,
    navigationRailTheme: .new(
      labelType: .selected,
      unselectedIconTheme: .new(color: colorScheme.onSurfaceVariant),
    ),
    iconButtonTheme: .new(
      style: .new(iconColor: .all(colorScheme.onSurfaceVariant)),
    ),
  );
}
