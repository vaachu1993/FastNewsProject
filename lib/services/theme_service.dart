import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app theme (light/dark mode)
class ThemeService {
  static const String _keyDarkMode = 'dark_mode_enabled';

  /// Check if dark mode is enabled
  Future<bool> isDarkModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyDarkMode) ?? false; // Default is light mode
    } catch (e) {
      print('Error reading dark mode preference: $e');
      return false;
    }
  }

  /// Set dark mode preference
  Future<bool> setDarkMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_keyDarkMode, enabled);
      print('Dark mode ${enabled ? 'enabled' : 'disabled'}: $success');
      return success;
    } catch (e) {
      print('Error saving dark mode preference: $e');
      return false;
    }
  }

  /// Toggle dark mode
  Future<bool> toggleDarkMode() async {
    final currentMode = await isDarkModeEnabled();
    return await setDarkMode(!currentMode);
  }
}

