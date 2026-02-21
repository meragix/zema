import 'package:zema/src/error/i18n.dart';

/// English translations (default)
final ZemaTranslations englishTranslations = {
  'invalid_type': (p) => 'Expected ${p?['expected']}, got ${p?['received']}',
  'too_short': (p) => 'Must be at least ${p?['min']} characters',
  'too_long': (p) => 'Must be at most ${p?['max']} characters',
  'too_small': (p) => 'Must be >= ${p?['min']}',
  'too_big': (p) => 'Must be <= ${p?['max']}',
  'invalid_email': (p) => 'Invalid email format',
  'invalid_url': (p) => 'Invalid URL format',
  'invalid_uuid': (p) => 'Invalid UUID format',
  'invalid_enum': (p) => 'Must be one of: ${(p?['allowed'] as List?)?.join(', ')}',
  'invalid_format': (p) => 'Invalid format',
  'custom_error': (p) => (p?['message'] as String?) ?? 'Validation failed',
  'custom_validation_failed': (p) => (p?['message'] as String?) ?? 'Custom Validation failed',
  'required': (p) => 'This field is required',
  'invalid_coercion': (p) => 'Cannot convert to ${p?['type']}',
  'not_positive': (p) => 'Must be a positive number',
  'not_negative': (p) => 'Must be a negative number',
  'not_finite': (p) => 'Must be a finite number',
  'transform_error': (p) => 'Failed to construct object',
  'not_multiple_of': (p) => 'Must be a multiple of ${p?['multipleOf']}',
  'invalid_union': (p) => 'Value does not match any union member',
  'invalid_literal': (p) => 'Expected literal value: ${p?['expected']}, got: ${p?['received']}',
  'invalid_date': (p) => 'Expected DateTime, ISO 8601 string, or timestamp',
  'date_too_early': (p) => 'Date must be after ${p?['min']}',
  'date_too_late': (p) => 'Date must be before ${p?['max']}',
};
