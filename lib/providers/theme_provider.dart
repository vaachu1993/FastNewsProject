import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// Provider that manages app theme state
class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Load theme preference from storage
  Future<void> _loadThemePreference() async {
    _isDarkMode = await _themeService.isDarkModeEnabled();
    notifyListeners();
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _themeService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  /// Set dark mode explicitly
  Future<void> setDarkMode(bool enabled) async {
    if (_isDarkMode != enabled) {
      _isDarkMode = enabled;
      await _themeService.setDarkMode(enabled);
      notifyListeners();
    }
  }

  /// Get light theme
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF5A7D3C),
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF5A7D3C),
        secondary: Colors.green,
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54),
      ),
    );
  }

  /// Get dark theme
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF5A7D3C),
      scaffoldBackgroundColor: const Color(0xFF1F1D36),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF5A7D3C),
        secondary: Colors.green,
        surface: const Color(0xFF2A2740),
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2A2740),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A2740),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2A2740),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
      ),
    );
  }

  /// Get current theme based on dark mode state
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;
}

