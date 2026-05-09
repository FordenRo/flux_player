import 'package:flutter/material.dart';

final mainPageController = MainPageController._internal();

class MainPageController with ChangeNotifier {
  var _pageIndex = 0;

  int get pageIndex => _pageIndex;
  set pageIndex(int value) {
    _pageIndex = value;
    notifyListeners();
  }

  MainPageController._internal();
}
