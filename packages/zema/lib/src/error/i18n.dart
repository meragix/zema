// Translation map for error messages
typedef ZemaTranslations = Map<String, String Function(Map<String, dynamic>?)>;

/// Localization manager
class ZemaI18n {
  static final Map<String, ZemaTranslations> _translations = {
    'en': _englishTranslations,
    'fr': _frenchTranslations,
  };

  /// Register custom translations for a locale
  static void registerTranslations(String locale, ZemaTranslations translations) {
    _translations[locale] = translations;
  }

  /// Get translation for a code
  static String translate(String code, {Map<String, dynamic>? params}) {
    final locale = ZemaErrorMap.locale;
    final translations = _translations[locale] ?? _translations['en']!;
    final translator = translations[code];

    if (translator == null) {
      // Fallback to English
      final fallback = _translations['en']![code];
      return fallback?.call(params) ?? 'Validation error: $code';
    }

    return translator(params);
  }
}