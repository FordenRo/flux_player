import 'package:flutter/material.dart';

final mainPageController = AppController._internal();

class AppController with ChangeNotifier {
  var _pageIndex = 0;

  int get pageIndex => _pageIndex;
  set pageIndex(int value) {
    _pageIndex = value;
    notifyListeners();
  }

  AppController._internal();
}
