import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class AppLanguageService extends ChangeNotifier {
  factory AppLanguageService() => _instance;
  AppLanguageService._();

  static final AppLanguageService _instance = AppLanguageService._();

  static const String _languageCodeKey = 'app_language_code';

  Locale? _selectedLocale;

  Locale? get selectedLocale => _selectedLocale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageCodeKey);

    if (savedCode == null) {
      _selectedLocale = null;
      return;
    }

    final supported = AppLocalizations.supportedLocales.where(
      (locale) => locale.languageCode == savedCode,
    );

    _selectedLocale = supported.isNotEmpty ? supported.first : null;
  }

  Future<void> setSelectedLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();

    if (locale == null) {
      await prefs.remove(_languageCodeKey);
    } else {
      await prefs.setString(_languageCodeKey, locale.languageCode);
    }

    _selectedLocale = locale;
    notifyListeners();
  }
}
