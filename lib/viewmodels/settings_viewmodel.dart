import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  double _textScaleFactor = 1.0;
  String _locale = 'id';

  // Notification settings
  bool _notifEvent = true;
  bool _notifTim = true;
  bool _notifLostFound = true;
  bool _notifAnnouncement = true;

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  String get locale => _locale;

  bool get notifEvent => _notifEvent;
  bool get notifTim => _notifTim;
  bool get notifLostFound => _notifLostFound;
  bool get notifAnnouncement => _notifAnnouncement;

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

    // Load Notification Settings
    _notifEvent = prefs.getBool('notif_event') ?? true;
    _notifTim = prefs.getBool('notif_tim') ?? true;
    _notifLostFound = prefs.getBool('notif_lost_found') ?? true;
    _notifAnnouncement = prefs.getBool('notif_announcement') ?? true;

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

  Future<void> setNotifEvent(bool value) async {
    _notifEvent = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_event', value);
  }

  Future<void> setNotifTim(bool value) async {
    _notifTim = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_tim', value);
  }

  Future<void> setNotifLostFound(bool value) async {
    _notifLostFound = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_lost_found', value);
  }

  Future<void> setNotifAnnouncement(bool value) async {
    _notifAnnouncement = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_announcement', value);
  }
}
