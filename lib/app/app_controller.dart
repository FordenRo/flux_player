import 'package:flutter/material.dart';

final appController = AppController._internal();

class AppController with ChangeNotifier {
  AppController._internal();
  var _pageIndex = 0;

  int get pageIndex => _pageIndex;
  set pageIndex(int value) {
    _pageIndex = value;
    notifyListeners();
  }
}
