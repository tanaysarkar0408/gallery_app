import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeData _lightTheme = ThemeData.light();
  final ThemeData _darkTheme = ThemeData.dark();

  ThemeData _currentTheme = ThemeData.dark();

  ThemeData get currentTheme => _currentTheme;

  void toggleTheme() {
    _currentTheme = _currentTheme == _lightTheme ? _darkTheme : _lightTheme;
    notifyListeners();
  }
}
