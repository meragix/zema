import 'package:zema/src/error/i18n.dart';

/// French translations
final ZemaTranslations frenchTranslations = {
  'invalid_type': (p) => 'Attendu ${p?['expected']}, reçu ${p?['received']}',
  'too_short': (p) => 'Doit contenir au moins ${p?['min']} caractères',
  'too_long': (p) => 'Doit contenir au maximum ${p?['max']} caractères',
  'too_small': (p) => 'Doit être >= ${p?['min']}',
  'too_big': (p) => 'Doit être <= ${p?['max']}',
  'invalid_email': (p) => 'Format d\'email invalide',
  'invalid_url': (p) => 'Format d\'URL invalide',
  'invalid_uuid': (p) => 'Format d\'UUID invalide',
  'invalid_enum': (p) =>
      'Doit être l\'un de: ${(p?['allowed'] as List?)?.join(', ')}',
  'invalid_format': (p) => 'Format invalide',
  'custom_error': (p) => (p?['message'] as String?) ?? 'Validation échouée',
  'required': (p) => 'Ce champ est requis',
  'invalid_coercion': (p) => 'Impossible de convertir en ${p?['type']}',
  'not_positive': (p) => 'Doit être un nombre positif',
  'not_negative': (p) => 'Doit être un nombre négatif',
  'not_finite': (p) => 'Doit être un nombre fini',
};
