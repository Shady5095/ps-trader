import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const String localeKey = 'app_language_code';

  LocaleCubit([super.initialLocale = const Locale('ar')]) {
    _loadSavedLocale();
  }

  bool get isArabic => state.languageCode == 'ar';

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString(localeKey);
      if (langCode != null && (langCode == 'ar' || langCode == 'en')) {
        if (state.languageCode != langCode) {
          emit(Locale(langCode));
        }
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state != locale) {
      emit(locale);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(localeKey, locale.languageCode);
      } catch (e) {
        debugPrint('Error saving locale: $e');
      }
    }
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    await setLocale(next);
  }
}
