import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  double _textScaleFactor = 1.0;
  String _locale = 'id';

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  String get locale => _locale;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final themeString = prefs.getString('themeMode') ?? 'light';
    if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    // Load Text Scale
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;

    // Load Locale
    _locale = prefs.getString('locale') ?? 'id';

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setTextScaleFactor(double scale) async {
    _textScaleFactor = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScaleFactor', scale);
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
  }
}
