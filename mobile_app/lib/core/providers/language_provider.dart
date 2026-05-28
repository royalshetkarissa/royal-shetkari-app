import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/language_api_service.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_language_code';
  Locale _currentLocale = const Locale('en');
  final LanguageApiService _apiService = LanguageApiService();

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  // Load saved language code from Shared Preferences or fallback to system locale
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null) {
        _currentLocale = Locale(savedCode);
      } else {
        // Fallback to default Locale('en')
        _currentLocale = const Locale('en');
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading saved language: $e");
    }
  }

  // Change active language, persist to shared preferences, and notify UI
  Future<void> changeLocale(Locale locale) async {
    if (_currentLocale.languageCode == locale.languageCode) return;

    _currentLocale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, locale.languageCode);

      // If token exists, sync with the backend
      final token = prefs.getString('token');
      if (token != null) {
        _apiService
            .updateLanguagePreference(locale.languageCode)
            .then((success) {
          if (success) {
            debugPrint(
                "Synced language preference '${locale.languageCode}' to backend.");
          } else {
            debugPrint(
                "Failed to sync language preference to backend (offline or server error). Saved locally.");
          }
        });
      }
    } catch (e) {
      debugPrint("Error saving language preference: $e");
    }
  }

  // Alias / helper for Step 4
  Future<void> changeLanguage(String languageCode) async {
    await changeLocale(Locale(languageCode));
  }
}
