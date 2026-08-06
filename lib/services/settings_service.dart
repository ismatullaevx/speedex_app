import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the user's preferred [ThemeMode].
class SettingsService {
  static const _themeModeKey = 'speedex_theme_mode';

  /// Loads the saved [ThemeMode]. Defaults to [ThemeMode.system].
  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeModeKey);
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
  }

  /// Persists [mode] to SharedPreferences.
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }
}
