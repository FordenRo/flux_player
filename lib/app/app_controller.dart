import 'package:flutter/material.dart';

import '../core/constants.dart';

final appController = AppController._();

enum AppPages { allTracks, playlists, settings }

class AppController with ChangeNotifier {
  AppController._() {
    _updateThemeData();
  }

  AppPages _currentPage = .allTracks;
  late ThemeData _themeData;
  Color _themePrimaryColor = themeColors.first;
  var _isThemeDark = true;

  ThemeData get themeData => _themeData;

  bool get isThemeDark => _isThemeDark;
  set isThemeDark(bool value) {
    _isThemeDark = value;
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
        brightness: isThemeDark ? .dark : .light,
      ),
    );
  }
}
