import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// Manages and persists the app's [ThemeMode].
class SettingsProvider extends ChangeNotifier {
  final SettingsService _service;

  SettingsProvider({required this._service});

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;

  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoaded = false;

  /// Load the persisted theme preference. Call once at startup.
  Future<void> load() async {
    _themeMode = await _service.loadThemeMode();
    _isLoaded = true;
    notifyListeners();
  }

  /// Update theme and persist the new value.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _service.saveThemeMode(mode);
  }
}
