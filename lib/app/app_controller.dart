import 'package:flutter/material.dart';

final appController = AppController._();

enum AppPages { allTracks, playlists, settings }

class AppController with ChangeNotifier {
  AppController._();

  AppPages _currentPage = .allTracks;

  AppPages get currentPage => _currentPage;
  set currentPage(AppPages value) {
    _currentPage = value;
    notifyListeners();
  }
}
