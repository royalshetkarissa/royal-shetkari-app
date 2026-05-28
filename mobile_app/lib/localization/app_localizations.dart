import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  // Helper method to keep code clean when resolving translation from context
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Load translations from JSON
  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('assets/translations/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      return true;
    } catch (e) {
      debugPrint("Error loading localization file for ${locale.languageCode}: $e");
      _localizedStrings = {};
      return false;
    }
  }

  // Fetch translation value for a key
  String translate(String key, {String? defaultValue}) {
    return _localizedStrings[key] ?? defaultValue ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr', 'ta', 'gu'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Extention for cleaner build context references: context.translate('welcome')
extension TranslationExtension on BuildContext {
  String translate(String key, {String? defaultValue}) {
    return AppLocalizations.of(this)?.translate(key, defaultValue: defaultValue) ?? defaultValue ?? key;
  }
}
