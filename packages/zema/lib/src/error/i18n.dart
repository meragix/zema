import 'package:zema/src/error/error_map.dart';
import 'package:zema/src/error/translations/en.dart';
import 'package:zema/src/error/translations/fr.dart';

/// Translation map for error messages
typedef ZemaTranslations = Map<String, String Function(Map<String, dynamic>?)>;

/// Localization manager
class ZemaI18n {
  static final Map<String, ZemaTranslations> _translations = {
    'en': englishTranslations,
    'fr': frenchTranslations,
  };

  // Cached active translations to avoid a Map lookup on every translate() call.
  static ZemaTranslations _active = englishTranslations;
  static String _activeLocale = 'en';

  /// Register custom translations for a locale
  static void registerTranslations(
    String locale,
    ZemaTranslations translations,
  ) {
    _translations[locale] = translations;
    // Invalidate cache if the registered locale is currently active.
    if (locale == _activeLocale) {
      _active = translations;
    }
  }

  /// Get translation for a code
  static String translate(String code, {Map<String, dynamic>? params}) {
    final locale = ZemaErrorMap.locale;
    if (locale != _activeLocale) {
      _activeLocale = locale;
      _active = _translations[locale] ?? _translations['en']!;
    }
    final translator = _active[code];

    if (translator == null) {
      // Fallback to English
      final fallback = _translations['en']![code];
      return fallback?.call(params) ?? 'Validation error: $code';
    }

    return translator(params);
  }
}
