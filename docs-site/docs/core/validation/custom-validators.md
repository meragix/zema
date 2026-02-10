---
sidebar_position: 3
description: Write custom validation logic for complex use cases
---

# Custom Validators

Learn how to write custom validation logic for your specific use cases.

---

## Custom Validator Functions

### Basic Custom Validator

```dart
// Define reusable validator
bool isValidUsername(String username) {
  if (username.length < 3) return false;
  if (username.length > 20) return false;
  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) return false;
  return true;
}

// Use with refine
final usernameSchema = z.string().refine(
  isValidUsername,
  message: 'Invalid username format',
);

// Or with custom type
final usernameSchema2 = z.custom<String>(
  validate: (value) {
    if (value is! String) return 'Expected string';
    if (!isValidUsername(value)) return 'Invalid username format';
    return null;
  },
);
```

---

## Validator Classes

### Reusable Validator Class

```dart
class PasswordValidator {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumber;
  final bool requireSpecial;

  PasswordValidator({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumber = true,
    this.requireSpecial = false,
  });

  String? validate(String password) {
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }

    if (requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }

    if (requireNumber && !password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain number';
    }

    if (requireSpecial && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain special character';
    }

    return null;
  }

  ZemaSchema<String> get schema {
    return z.custom<String>(
      validate: (value) {
        if (value is! String) return 'Expected string';
        return validate(value);
      },
    );
  }
}

// Usage
final strictValidator = PasswordValidator(
  minLength: 12,
  requireUppercase: true,
  requireLowercase: true,
  requireNumber: true,
  requireSpecial: true,
);

final passwordSchema = strictValidator.schema;

passwordSchema.parse('WeakPass123');
// ❌ Password must contain special character
```

---

## Composable Validators

### Validator Composition

```dart
// Simple validator functions
bool hasMinLength(String s, int min) => s.length >= min;
bool hasMaxLength(String s, int max) => s.length <= max;
bool hasUppercase(String s) => s.contains(RegExp(r'[A-Z]'));
bool hasLowercase(String s) => s.contains(RegExp(r'[a-z]'));
bool hasNumber(String s) => s.contains(RegExp(r'[0-9]'));
bool hasSpecialChar(String s) => s.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

// Compose validators
class CompositeValidator {
  final List<bool Function(String)> validators;
  final List<String> errorMessages;

  CompositeValidator(this.validators, this.errorMessages)
      : assert(validators.length == errorMessages.length);

  List<String> validate(String value) {
    final errors = <String>[];

    for (var i = 0; i < validators.length; i++) {
      if (!validators[i](value)) {
        errors.add(errorMessages[i]);
      }
    }

    return errors;
  }

  ZemaSchema<String> get schema {
    return z.custom<String>(
      validate: (value) {
        if (value is! String) return 'Expected string';

        final errors = validate(value);

        if (errors.isEmpty) return null;

        return errors.join('; ');
      },
    );
  }
}

// Usage
final passwordValidator = CompositeValidator(
  [
    (s) => hasMinLength(s, 8),
    (s) => hasUppercase(s),
    (s) => hasLowercase(s),
    (s) => hasNumber(s),
  ],
  [
    'Minimum 8 characters',
    'Must contain uppercase',
    'Must contain lowercase',
    'Must contain number',
  ],
);

final passwordSchema = passwordValidator.schema;
```

---

## Domain-Specific Validators

### Email Validator

```dart
class EmailValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final List<String>? allowedDomains;
  final List<String>? blockedDomains;

  EmailValidator({
    this.allowedDomains,
    this.blockedDomains,
  });

  String? validate(String email) {
    if (!_emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }

    final domain = email.split('@').last.toLowerCase();

    if (allowedDomains != null && !allowedDomains!.contains(domain)) {
      return 'Email domain not allowed. Use one of: ${allowedDomains!.join(', ')}';
    }

    if (blockedDomains != null && blockedDomains!.contains(domain)) {
      return 'Email domain is blocked';
    }

    return null;
  }

  ZemaSchema<String> get schema {
    return z.custom<String>(
      validate: (value) {
        if (value is! String) return 'Expected string';
        return validate(value);
      },
    );
  }
}

// Usage - Corporate email only
final corporateEmailValidator = EmailValidator(
  allowedDomains: ['company.com', 'company.co.uk'],
);

final emailSchema = corporateEmailValidator.schema;

emailSchema.parse('alice@company.com');  // ✅
emailSchema.parse('alice@gmail.com');    // ❌ Domain not allowed
```

---

### Credit Card Validator

```dart
class CreditCardValidator {
  static bool luhnCheck(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '').split('');
    if (digits.length < 13 || digits.length > 19) return false;

    var sum = 0;
    var isEven = false;

    for (var i = digits.length - 1; i >= 0; i--) {
      var digit = int.parse(digits[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 == 0;
  }

  static String? detectCardType(String cardNumber) {
    final digitsOnly = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (RegExp(r'^4').hasMatch(digitsOnly)) return 'Visa';
    if (RegExp(r'^5[1-5]').hasMatch(digitsOnly)) return 'Mastercard';
    if (RegExp(r'^3[47]').hasMatch(digitsOnly)) return 'American Express';
    if (RegExp(r'^6(?:011|5)').hasMatch(digitsOnly)) return 'Discover';

    return null;
  }

  final List<String>? acceptedTypes;

  CreditCardValidator({this.acceptedTypes});

  String? validate(String cardNumber) {
    if (cardNumber.isEmpty) {
      return 'Card number is required';
    }

    final digitsOnly = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
      return 'Card number must be 13-19 digits';
    }

    if (!luhnCheck(cardNumber)) {
      return 'Invalid card number';
    }

    if (acceptedTypes != null) {
      final cardType = detectCardType(cardNumber);

      if (cardType == null) {
        return 'Unknown card type';
      }

      if (!acceptedTypes!.contains(cardType)) {
        return 'Card type not accepted. We accept: ${acceptedTypes!.join(', ')}';
      }
    }

    return null;
  }

  ZemaSchema<String> get schema {
    return z.custom<String>(
      validate: (value) {
        if (value is! String) return 'Expected string';
        return validate(value);
      },
    ).transform((value) {
      // Normalize to digits only
      return (value as String).replaceAll(RegExp(r'\D'), '');
    });
  }
}

// Usage - Only accept Visa and Mastercard
final cardValidator = CreditCardValidator(
  acceptedTypes: ['Visa', 'Mastercard'],
);

final cardSchema = cardValidator.schema;

cardSchema.parse('4532 0151 1283 0366');  // ✅ Visa
cardSchema.parse('3782 822463 10005');    // ❌ Amex not accepted
```

---

### Phone Number Validator

```dart
class PhoneValidator {
  final String defaultCountryCode;
  final List<String> allowedCountryCodes;

  PhoneValidator({
    this.defaultCountryCode = '1',
    this.allowedCountryCodes = const ['1'],
  });

  String? validate(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    var digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Add default country code if missing
    if (!digitsOnly.startsWith(RegExp(r'^[0-9]{1,3}'))) {
      digitsOnly = defaultCountryCode + digitsOnly;
    }

    // Extract country code (first 1-3 digits)
    String? countryCode;
    for (var i = 1; i <= 3 && i <= digitsOnly.length; i++) {
      final code = digitsOnly.substring(0, i);
      if (allowedCountryCodes.contains(code)) {
        countryCode = code;
        break;
      }
    }

    if (countryCode == null) {
      return 'Invalid or unsupported country code';
    }

    final numberWithoutCode = digitsOnly.substring(countryCode.length);

    if (numberWithoutCode.length < 10) {
      return 'Phone number too short';
    }

    if (numberWithoutCode.length > 15) {
      return 'Phone number too long';
    }

    return null;
  }

  ZemaSchema<String> get schema {
    return z.custom<String>(
      validate: (value) {
        if (value is! String) return 'Expected string';
        return validate(value);
      },
    ).transform((value) {
      // Normalize to E.164 format: +[country][number]
      var digitsOnly = (value as String).replaceAll(RegExp(r'\D'), '');

      if (!digitsOnly.startsWith(RegExp(r'^[0-9]{1,3}'))) {
        digitsOnly = defaultCountryCode + digitsOnly;
      }

      return '+$digitsOnly';
    });
  }
}

// Usage
final phoneValidator = PhoneValidator(
  defaultCountryCode: '1',
  allowedCountryCodes: ['1', '44', '33'],  // US, UK, France
);

final phoneSchema = phoneValidator.schema;

phoneSchema.parse('(555) 123-4567');     // ✅ +15551234567
phoneSchema.parse('+44 20 7946 0958');   // ✅ +442079460958
```

---

## Validation with External Services

### Database Uniqueness Check

```dart
class UniquenessValidator<T> {
  final Future<bool> Function(T value) checkExists;
  final String fieldName;

  UniquenessValidator({
    required this.checkExists,
    required this.fieldName,
  });

  Future<String?> validate(T value) async {
    final exists = await checkExists(value);

    if (exists) {
      return '$fieldName already exists';
    }

    return null;
  }

  // Async schema (covered in async-validation.md)
  ZemaSchema<T> get schema {
    return z.custom<T>(
      validate: (value) {
        if (value is! T) return 'Invalid type';
        // Note: Cannot use async in custom validator
        // Use refineAsync instead (see async-validation.md)
        return null;
      },
    );
  }
}
```

---

## Error Aggregation

### Collect All Validation Errors

```dart
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult(this.isValid, this.errors);

  ValidationResult.valid() : this(true, []);
  ValidationResult.invalid(List<String> errors) : this(false, errors);
}

class AggregateValidator {
  final Map<String, String? Function(dynamic)> validators;

  AggregateValidator(this.validators);

  ValidationResult validate(Map<String, dynamic> data) {
    final errors = <String>[];

    validators.forEach((field, validator) {
      final value = data[field];
      final error = validator(value);

      if (error != null) {
        errors.add('$field: $error');
      }
    });

    return errors.isEmpty
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }

  ZemaSchema<Map<String, dynamic>> get schema {
    return z.custom<Map<String, dynamic>>(
      validate: (value) {
        if (value is! Map<String, dynamic>) return 'Expected object';

        final result = validate(value);

        if (result.isValid) return null;

        return result.errors.join('; ');
      },
    );
  }
}

// Usage
final userValidator = AggregateValidator({
  'email': (v) => v is String && v.contains('@') ? null : 'Invalid email',
  'age': (v) => v is int && v >= 18 ? null : 'Must be 18+',
  'username': (v) {
    if (v is! String) return 'Expected string';
    if (v.length < 3) return 'Min 3 characters';
    if (v.length > 20) return 'Max 20 characters';
    return null;
  },
});

final result = userValidator.validate({
  'email': 'invalid',
  'age': 15,
  'username': 'ab',
});

print(result.errors);
// [
//   'email: Invalid email',
//   'age: Must be 18+',
//   'username: Min 3 characters'
// ]
```

---

## Conditional Validators

### Context-Aware Validation

```dart
class ConditionalValidator {
  final bool Function(Map<String, dynamic>) condition;
  final String? Function(dynamic) validator;
  final String field;

  ConditionalValidator({
    required this.condition,
    required this.validator,
    required this.field,
  });

  String? validate(Map<String, dynamic> data) {
    if (condition(data)) {
      return validator(data[field]);
    }
    return null;
  }
}

// Example: Admin requires adminKey
final adminKeyValidator = ConditionalValidator(
  condition: (data) => data['role'] == 'admin',
  validator: (value) {
    if (value == null || value.toString().isEmpty) {
      return 'Admin key is required for admin role';
    }
    return null;
  },
  field: 'adminKey',
);

final userSchema = z.object({
  'role': z.enum(['user', 'admin']),
  'adminKey': z.string().optional(),
}).refine(
  (data) => adminKeyValidator.validate(data) == null,
  message: (data) => adminKeyValidator.validate(data)!,
  path: ['adminKey'],
);
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Create reusable validator classes
class PasswordValidator {
  String? validate(String password) {...}
  ZemaSchema<String> get schema {...}
}

// ✅ Provide detailed error messages
return 'Password must be at least 8 characters, got ${password.length}';

// ✅ Use type parameters
z.custom<Email>(...)  // Type-safe

// ✅ Compose simple validators
final validator = CompositeValidator([...], [...]);

// ✅ Document complex logic
/// Validates credit card using Luhn algorithm
String? validate(String cardNumber) {...}
```

---

### ❌ DON'T

```dart
// ❌ Don't do heavy I/O in sync validators
z.custom(validate: (v) {
  final exists = database.query(v);  // Blocking I/O!
  return exists ? 'Exists' : null;
});
// Use async validation instead

// ❌ Don't throw exceptions
z.custom(validate: (v) {
  if (invalid) throw Exception('Invalid!');  // ❌
});

// ❌ Don't validate UI state
z.custom(validate: (v) {
  if (isButtonPressed) return 'Error';  // ❌ UI state
});

// ❌ Don't use generic error messages
return 'Invalid';  // ❌ Not helpful
// Use: 'Email must contain @ symbol'
```

---

## Testing Custom Validators

```dart
void main() {
  group('PasswordValidator', () {
    final validator = PasswordValidator(minLength: 8);

    test('accepts strong password', () {
      final result = validator.schema.parse('StrongPass123!');
      expect(result.isSuccess, true);
    });

    test('rejects short password', () {
      final result = validator.schema.parse('Weak1!');
      expect(result.isFailure, true);
      expect(
        result.errors.first.message,
        contains('at least 8 characters'),
      );
    });

    test('rejects password without uppercase', () {
      final result = validator.schema.parse('lowercase123!');
      expect(result.isFailure, true);
      expect(
        result.errors.first.message,
        contains('uppercase'),
      );
    });
  });
}
```

---

## API Reference

### Custom Validator Pattern

```dart
class MyValidator {
  // Configuration
  final Type config;

  MyValidator({this.config});

  // Validation logic
  String? validate(T value) {
    // Return null if valid
    // Return error message if invalid
  }

  // Schema getter
  ZemaSchema<T> get schema {
    return z.custom<T>(
      validate: (value) {
        if (value is! T) return 'Expected T';
        return validate(value);
      },
    );
  }
}
```

---

## Next Steps

- [Async Validation →](./async-validation) - Validators with async operations
- [Refinements →](/docs/core/schemas/refinements) - Add validation to existing schemas
- [Custom Types →](/docs/core/schemas/custom-types) - Define custom schema types
