import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// InheritedWidget to notify all descendants about language changes
class _LocalizationInheritedWidget extends InheritedWidget {
  final LocalizationProviderState data;

  const _LocalizationInheritedWidget({
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(_LocalizationInheritedWidget oldWidget) {
    return data.currentLanguage != oldWidget.data.currentLanguage;
  }
}

/// A widget that provides language change functionality to the entire app
class LocalizationProvider extends StatefulWidget {
  final Widget child;

  const LocalizationProvider({
    super.key,
    required this.child,
  });

  @override
  State<LocalizationProvider> createState() => LocalizationProviderState();

  /// Get the provider state from context (will cause rebuild on language change)
  static LocalizationProviderState? of(BuildContext context) {
    final inheritedWidget = context.dependOnInheritedWidgetOfExactType<_LocalizationInheritedWidget>();
    return inheritedWidget?.data;
  }
}

class LocalizationProviderState extends State<LocalizationProvider> {
  final LocalizationService _localizationService = LocalizationService();

  String get currentLanguage => _localizationService.currentLanguage;
  Locale get currentLocale => _localizationService.currentLocale;

  /// Change the app language and rebuild the entire app
  Future<void> changeLanguage(String languageCode) async {
    await _localizationService.setLanguage(languageCode);
    setState(() {}); // This will rebuild and notify all dependents
  }

  @override
  Widget build(BuildContext context) {
    return _LocalizationInheritedWidget(
      data: this,
      child: widget.child,
    );
  }
}

