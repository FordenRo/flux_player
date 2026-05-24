import 'package:flutter/material.dart';

export 'src/radiuses.dart';
export 'src/styles.dart';

final appTheme = AppTheme._();

class AppTheme with ChangeNotifier {
  AppTheme._();

  ThemeData _themeData = getThemeData(color: Colors.red, brightness: .dark);

  ThemeData get themeData => _themeData;
  set themeData(ThemeData value) {
    _themeData = value;
    notifyListeners();
  }
}

ThemeData getThemeData({required Color color, required Brightness brightness}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: color,
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
