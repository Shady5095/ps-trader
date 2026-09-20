import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocale {
  AppLocale(this.locale);

  Locale? locale;
  Map<String, String>? _loadedLocalizedValues;
  static final Map<String, Map<String, String>> _cachedTranslations = {};

  static AppLocale of(BuildContext context) {
    return Localizations.of<AppLocale>(context, AppLocale)!;
  }

  /// تحميل ملف اللغة وحفظه في الذاكرة
  Future<void> loadLang() async {
    final langCode = locale?.languageCode ?? 'ar';
    if (_cachedTranslations.containsKey(langCode)) {
      _loadedLocalizedValues = _cachedTranslations[langCode];
      return;
    }

    try {
      debugPrint('📝 [LOCALE] Loading language file for: $langCode');
      final String langFile = await rootBundle.loadString(
        'assets/lang/$langCode.json',
      );
      debugPrint('📝 [LOCALE] Language file loaded, length: ${langFile.length}');

      final Map<String, dynamic> loadedValues = jsonDecode(langFile);
      debugPrint('📝 [LOCALE] JSON decoded, entries: ${loadedValues.length}');

      _loadedLocalizedValues = loadedValues.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      _cachedTranslations[langCode] = _loadedLocalizedValues!;
      debugPrint('📝 [LOCALE] Language loaded successfully with ${_loadedLocalizedValues?.length} translations');
    } catch (e, stackTrace) {
      debugPrint('❌ [LOCALE] Error loading language file: $e');
      debugPrint('❌ [LOCALE] Stack trace: $stackTrace');
      _loadedLocalizedValues = {};
    }
  }

  String? getTranslated(String key) {
    return _loadedLocalizedValues?[key] ?? key;
  }

  static const LocalizationsDelegate<AppLocale> delegate = _AppLocalDelegate();
}

class _AppLocalDelegate extends LocalizationsDelegate<AppLocale> {
  const _AppLocalDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'tr', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocale> load(Locale locale) async {
    final AppLocale appLocale = AppLocale(locale);
    await appLocale.loadLang();
    return appLocale;
  }

  /// إعادة التحميل عند Hot Reload
  @override
  bool shouldReload(_AppLocalDelegate old) => true;
}

/// Getter for translation
String getLang(BuildContext context, String key) {
  final appLocale = Localizations.of<AppLocale>(context, AppLocale);
  return appLocale?.getTranslated(key) ?? key;
}

/// Check if current locale is Arabic
bool isArabic(BuildContext context) {
  final Locale myLocale = Localizations.localeOf(context);
  return myLocale.languageCode == 'ar';
}

/// Extension for easy translation: AppStrings.home.tr(context)
extension TranslateLanguage on String {
  String tr(BuildContext context) => getLang(context, this);
}

