import 'package:flutter/material.dart';

final appController = AppController._internal();

enum AppPages { allTracks, playlists, settings }

class AppController with ChangeNotifier {
  AppController._internal() {
    _updateThemeData();
  }

  AppPages _currentPage = .allTracks;
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

  AppPages get currentPage => _currentPage;
  set currentPage(AppPages value) {
    _currentPage = value;
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
