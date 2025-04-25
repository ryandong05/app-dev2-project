import 'package:flutter/material.dart';

class SettingsModel extends ChangeNotifier {
  // Theme settings
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Language settings
  String _currentLanguage = 'English';
  String get currentLanguage => _currentLanguage;

  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  // Notification settings
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }
}
