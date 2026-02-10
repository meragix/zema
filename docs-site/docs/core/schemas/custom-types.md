---
sidebar_position: 7
description: Create your own schema types with z.custom()
---

# Custom Types

Create completely custom validation logic with `z.custom()`.

---

## Basic Custom Type

```dart
final evenNumberSchema = z.custom<int>(
  validate: (value) {
    if (value is! int) {
      return 'Expected integer, got ${value.runtimeType}';
    }
    if (value % 2 != 0) {
      return 'Must be an even number';
    }
    return null;  // null = valid
  },
);

evenNumberSchema.parse(42);   // ✅ ZemaSuccess(42)
evenNumberSchema.parse(43);   // ❌ Must be an even number
evenNumberSchema.parse('42'); // ❌ Expected integer, got String
```

**Validation function signature:**

```dart
String? validate(dynamic value) {
  // Return null if valid
  // Return error message if invalid
}
```

---

## Custom Type with Type Parameter

```dart
// Email type
final emailSchema = z.custom<String>(
  validate: (value) {
    if (value is! String) {
      return 'Expected string, got ${value.runtimeType}';
    }
    if (!value.contains('@')) {
      return 'Invalid email format';
    }
    return null;
  },
);

// UUID type
final uuidSchema = z.custom<String>(
  validate: (value) {
    if (value is! String) {
      return 'Expected string';
    }
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (!uuidRegex.hasMatch(value)) {
      return 'Invalid UUID format';
    }
    return null;
  },
);
```

---

## Custom Type with Transformation

```dart
// Parse hex color to Color object
final colorSchema = z.custom<Color>(
  validate: (value) {
    if (value is! String) {
      return 'Expected hex color string';
    }
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
      return 'Invalid hex color format';
    }
    return null;
  },
).transform((value) {
  final hex = value as String;
  final colorValue = int.parse(hex.substring(1), radix: 16);
  return Color(0xFF000000 + colorValue);
});

colorSchema.parse('#FF5733');
// ✅ ZemaSuccess(Color(0xFFFF5733))
```

---

## Reusable Custom Types

### Positive Integer

```dart
final positiveIntSchema = z.custom<int>(
  validate: (value) {
    if (value is! int) return 'Expected integer';
    if (value <= 0) return 'Must be positive';
    return null;
  },
);

// Use in objects
final productSchema = z.object({
  'price': positiveIntSchema,
  'stock': positiveIntSchema,
});
```

---

### URL

```dart
final urlSchema = z.custom<String>(
  validate: (value) {
    if (value is! String) return 'Expected string';
    
    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme) return 'URL must have a scheme (http/https)';
      if (!uri.hasAuthority) return 'URL must have a domain';
      return null;
    } catch (e) {
      return 'Invalid URL format';
    }
  },
);

urlSchema.parse('https://example.com');  // ✅
urlSchema.parse('not a url');            // ❌
```

---

### Phone Number

```dart
final phoneSchema = z.custom<String>(
  validate: (value) {
    if (value is! String) return 'Expected string';
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Phone number must be 10-15 digits';
    }
    
    return null;
  },
).transform((value) {
  // Normalize phone number
  final digitsOnly = (value as String).replaceAll(RegExp(r'\D'), '');
  return '+$digitsOnly';
});

phoneSchema.parse('+1 (555) 123-4567');
// ✅ ZemaSuccess('+15551234567')
```

---

## Custom Types for Domain Objects

### Money

```dart
class Money {
  final double amount;
  final String currency;

  Money(this.amount, this.currency);

  @override
  String toString() => '$currency $amount';
}

final moneySchema = z.custom<Money>(
  validate: (value) {
    if (value is! Map) return 'Expected object with amount and currency';
    
    if (!value.containsKey('amount')) return 'Missing amount';
    if (!value.containsKey('currency')) return 'Missing currency';
    
    if (value['amount'] is! num) return 'Amount must be a number';
    if (value['currency'] is! String) return 'Currency must be a string';
    
    if (value['currency'].toString().length != 3) {
      return 'Currency must be 3-letter code (e.g., USD)';
    }
    
    return null;
  },
).transform((value) {
  final map = value as Map;
  return Money(
    (map['amount'] as num).toDouble(),
    map['currency'] as String,
  );
});

moneySchema.parse({'amount': 19.99, 'currency': 'USD'});
// ✅ ZemaSuccess(Money(19.99, 'USD'))
```

---

### Geolocation

```dart
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  @override
  String toString() => '($latitude, $longitude)';
}

final latLngSchema = z.custom<LatLng>(
  validate: (value) {
    if (value is! Map) return 'Expected object';
    
    if (!value.containsKey('lat') || !value.containsKey('lng')) {
      return 'Missing lat or lng';
    }
    
    final lat = value['lat'];
    final lng = value['lng'];
    
    if (lat is! num || lng is! num) {
      return 'Latitude and longitude must be numbers';
    }
    
    if (lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }
    
    if (lng < -180 || lng > 180) {
      return 'Longitude must be between -180 and 180';
    }
    
    return null;
  },
).transform((value) {
  final map = value as Map;
  return LatLng(
    (map['lat'] as num).toDouble(),
    (map['lng'] as num).toDouble(),
  );
});

latLngSchema.parse({'lat': 40.7128, 'lng': -74.0060});
// ✅ ZemaSuccess(LatLng(40.7128, -74.0060))
```

---

## Custom Type with Multiple Validators

```dart
final strongPasswordSchema = z.custom<String>(
  validate: (value) {
    if (value is! String) return 'Expected string';
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain number';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain special character';
    }
    
    return null;
  },
);
```

---

## Custom Type Factory

Create a factory function for reusable custom types:

```dart
// Factory for enum-like string validation
ZemaSchema<String> stringEnum(List<String> allowedValues) {
  return z.custom<String>(
    validate: (value) {
      if (value is! String) return 'Expected string';
      if (!allowedValues.contains(value)) {
        return 'Must be one of: ${allowedValues.join(', ')}';
      }
      return null;
    },
  );
}

// Usage
final statusSchema = stringEnum(['pending', 'active', 'completed', 'cancelled']);

statusSchema.parse('active');     // ✅
statusSchema.parse('unknown');    // ❌ Must be one of: pending, active, completed, cancelled
```

---

## Custom Type with Context

```dart
// Minimum age validator
ZemaSchema<DateTime> minimumAge(int years) {
  return z.custom<DateTime>(
    validate: (value) {
      if (value is! DateTime) return 'Expected DateTime';
      
      final age = DateTime.now().difference(value).inDays ~/ 365;
      
      if (age < years) {
        return 'Must be at least $years years old';
      }
      
      return null;
    },
  );
}

// Usage
final adultSchema = minimumAge(18);
final seniorSchema = minimumAge(65);

adultSchema.parse(DateTime(2000, 1, 1));   // ✅ (24 years old)
adultSchema.parse(DateTime(2010, 1, 1));   // ❌ Must be at least 18 years old
```

---

## Real-World Examples

### Credit Card Number

```dart
bool luhnCheck(String cardNumber) {
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

final creditCardSchema = z.custom<String>(
  validate: (value) {
    if (value is! String) return 'Expected string';
    
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length < 13 || digitsOnly.length > 19) {
      return 'Card number must be 13-19 digits';
    }
    
    if (!luhnCheck(value)) {
      return 'Invalid card number';
    }
    
    return null;
  },
).transform((value) {
  // Normalize to digits only
  return (value as String).replaceAll(RegExp(r'\D'), '');
});

creditCardSchema.parse('4532 0151 1283 0366');
// ✅ ZemaSuccess('4532015112830366')
```

---

### IP Address

```dart
final ipv4Schema = z.custom<String>(
  validate: (value) {
    if (value is! String) return 'Expected string';
    
    final parts = value.split('.');
    
    if (parts.length != 4) {
      return 'IPv4 address must have 4 octets';
    }
    
    for (final part in parts) {
      final num = int.tryParse(part);
      
      if (num == null) {
        return 'Invalid octet: $part';
      }
      
      if (num < 0 || num > 255) {
        return 'Octet must be 0-255, got $num';
      }
    }
    
    return null;
  },
);

ipv4Schema.parse('192.168.1.1');     // ✅
ipv4Schema.parse('256.1.1.1');       // ❌ Octet must be 0-255
ipv4Schema.parse('192.168.1');       // ❌ Must have 4 octets
```

---

### Slug

```dart
final slugSchema = z.custom<String>(
  validate: (value) {
    if (value is! String) return 'Expected string';
    
    if (value.isEmpty) return 'Slug cannot be empty';
    
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
      return 'Slug must be lowercase letters, numbers, and hyphens only';
    }
    
    if (value.startsWith('-') || value.endsWith('-')) {
      return 'Slug cannot start or end with hyphen';
    }
    
    if (value.contains('--')) {
      return 'Slug cannot contain consecutive hyphens';
    }
    
    return null;
  },
);

slugSchema.parse('my-blog-post');      // ✅
slugSchema.parse('My Blog Post');      // ❌ Uppercase not allowed
slugSchema.parse('my--post');          // ❌ Consecutive hyphens
```

---

## Performance Considerations

### Expensive Validation

```dart
// ❌ Slow: Heavy computation on every validation
final expensiveSchema = z.custom<String>(
  validate: (value) {
    // Heavy regex or database query
    return expensiveCheck(value) ? null : 'Invalid';
  },
);

// ✅ Better: Cache results
final _validationCache = <String, bool>{};

final cachedSchema = z.custom<String>(
  validate: (value) {
    if (value is! String) return 'Expected string';
    
    // Check cache first
    if (_validationCache.containsKey(value)) {
      return _validationCache[value]! ? null : 'Invalid';
    }
    
    // Do expensive check
    final isValid = expensiveCheck(value);
    _validationCache[value] = isValid;
    
    return isValid ? null : 'Invalid';
  },
);
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Return null for valid
z.custom<int>(validate: (v) => v is int && v > 0 ? null : 'Must be positive int');

// ✅ Provide specific error messages
z.custom<String>(validate: (v) {
  if (v is! String) return 'Expected string, got ${v.runtimeType}';
  if (v.length < 8) return 'Minimum 8 characters, got ${v.length}';
  return null;
});

// ✅ Use type parameter
z.custom<Email>(...);  // Type-safe
```

---

### ❌ DON'T

```dart
// ❌ Don't throw exceptions
z.custom(validate: (v) {
  if (invalid) throw Exception('Invalid!');  // ❌
});

// ❌ Don't use for built-in types
z.custom<String>(validate: (v) => v is String ? null : 'Not string');
// Use: z.string()

// ❌ Don't do heavy computation without caching
z.custom(validate: (v) => expensiveDatabaseQuery(v));
```

---

## API Reference

### z.custom()

```dart
z.custom<T>({
  required String? Function(dynamic value) validate,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `validate` | `String? Function(dynamic)` | Return `null` if valid, error message if invalid |
| `<T>` | Type parameter | Expected output type |

**Returns:** `ZemaSchema<T>`

---

## Next Steps

- [Refinements →](./refinements) - Add validation rules to existing schemas
- [Async Validation →](/docs/core/validation/async-validation) - Async custom validation
- [Transforms →](/docs/core/transformations/transforms) - Transform validated data
