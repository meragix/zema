/// English translations (default)
final ZemaTranslations _englishTranslations = {
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
    'custom_error': (p) => p?['message'] ?? 'Validation failed',
    'required': (p) => 'This field is required',
    'invalid_coercion': (p) => 'Cannot convert to ${p?['type']}',
  };