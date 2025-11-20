import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LocalizationService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'vi'; // Tiếng Việt mặc định

  // Singleton pattern
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  String _currentLanguage = _defaultLanguage;

  String get currentLanguage => _currentLanguage;

  /// Initialize and load saved language preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
  }

  /// Get current locale
  Locale get currentLocale {
    return _currentLanguage == 'vi'
        ? const Locale('vi', 'VN')
        : const Locale('en', 'US');
  }

  /// Change language and save preference
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'vi' && languageCode != 'en') {
      languageCode = _defaultLanguage;
    }

    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  /// Get supported locales
  static List<Locale> get supportedLocales => [
    const Locale('vi', 'VN'),
    const Locale('en', 'US'),
  ];
}

