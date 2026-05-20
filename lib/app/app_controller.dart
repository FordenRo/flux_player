import 'package:flutter/material.dart';

final appController = AppController._internal();

class AppController with ChangeNotifier {
  AppController._internal() {
    _updateThemeData();
  }

  var _pageIndex = 0;
  late ThemeData _themeData;
  Color _themePrimaryColor = Colors.red.shade400;
  var _darkTheme = true;

  ThemeData get themeData => _themeData;

  bool get darkTheme => _darkTheme;
  set darkTheme(bool value) {
    _darkTheme = value;
    _updateThemeData();
    notifyListeners();
  }

  Color get themePrimaryColor => _themePrimaryColor;
  set themePrimaryColor(Color value) {
    _themePrimaryColor = value;
    _updateThemeData();
    notifyListeners();
  }

  int get pageIndex => _pageIndex;
  set pageIndex(int value) {
    _pageIndex = value;
    notifyListeners();
  }

  void _updateThemeData() {
    _themeData = .new(
      colorScheme: .fromSeed(
        seedColor: themePrimaryColor,
        brightness: darkTheme ? .dark : .light,
      ),
    );
  }
}
