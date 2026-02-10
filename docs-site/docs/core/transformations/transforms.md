---
sidebar_position: 1
description: Transform validated data into different formats
---

# Transforms

Transform validated data into different types or formats after validation.

---

## Basic Transform

```dart
final schema = z.string().transform((value) => value.toUpperCase());

final result = schema.parse('hello');
// ✅ ZemaSuccess('HELLO')
```

**Transform signature:**

```dart
R transform<R>(R Function(T value) fn)
```

---

## Common Transformations

### String to Number

```dart
final schema = z.string()
  .regex(RegExp(r'^\d+$'), 'Must be numeric')
  .transform((s) => int.parse(s));

schema.parse('42');   // ✅ ZemaSuccess(42)
schema.parse('abc');  // ❌ Validation fails before transform
```

---

### String to DateTime

```dart
final dateSchema = z.string()
  .datetime()
  .transform((s) => DateTime.parse(s));

dateSchema.parse('2024-02-08T10:30:00Z');
// ✅ ZemaSuccess(DateTime(2024, 2, 8, 10, 30))
```

---

### String to Enum

```dart
enum UserRole { admin, user, guest }

final roleSchema = z.enum(['admin', 'user', 'guest'])
  .transform((value) {
    return UserRole.values.firstWhere((e) => e.name == value);
  });

roleSchema.parse('admin');
// ✅ ZemaSuccess(UserRole.admin)
```

---

### Timestamp to DateTime

```dart
// Milliseconds since epoch → DateTime
final timestampSchema = z.integer()
  .transform((ms) => DateTime.fromMillisecondsSinceEpoch(ms));

timestampSchema.parse(1707389400000);
// ✅ ZemaSuccess(DateTime(2024, 2, 8, ...))

// Seconds since epoch → DateTime
final secondsSchema = z.integer()
  .transform((s) => DateTime.fromMillisecondsSinceEpoch(s * 1000));

secondsSchema.parse(1707389400);
// ✅ ZemaSuccess(DateTime(2024, 2, 8, ...))
```

---

## Chaining Transforms

```dart
final schema = z.string()
  .transform((s) => s.trim())           // 1. Remove whitespace
  .transform((s) => s.toLowerCase())    // 2. Convert to lowercase
  .transform((s) => s.replaceAll(' ', '-'));  // 3. Spaces to hyphens

schema.parse('  Hello World  ');
// ✅ ZemaSuccess('hello-world')
```

---

## Object Transformations

### Map to Custom Object

```dart
class User {
  final int id;
  final String email;
  
  User({required this.id, required this.email});
}

final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
}).transform((map) => User(
  id: map['id'],
  email: map['email'],
));

userSchema.parse({
  'id': 123,
  'email': 'alice@example.com',
});
// ✅ ZemaSuccess(User(id: 123, email: 'alice@example.com'))
```

---

### Nested Object Transformation

```dart
final addressSchema = z.object({
  'street': z.string(),
  'city': z.string(),
  'country': z.string(),
}).transform((map) {
  return '${map['street']}, ${map['city']}, ${map['country']}';
});

addressSchema.parse({
  'street': '123 Main St',
  'city': 'New York',
  'country': 'USA',
});
// ✅ ZemaSuccess('123 Main St, New York, USA')
```

---

### Flatten Nested Objects

```dart
final schema = z.object({
  'user': z.object({
    'profile': z.object({
      'name': z.string(),
      'email': z.string(),
    }),
  }),
}).transform((data) {
  final profile = data['user']['profile'] as Map;
  return {
    'name': profile['name'],
    'email': profile['email'],
  };
});

schema.parse({
  'user': {
    'profile': {
      'name': 'Alice',
      'email': 'alice@example.com',
    },
  },
});
// ✅ ZemaSuccess({'name': 'Alice', 'email': 'alice@example.com'})
```

---

## Array Transformations

### Map Array Elements

```dart
final schema = z.array(z.string())
  .transform((list) => list.map((s) => s.toUpperCase()).toList());

schema.parse(['hello', 'world']);
// ✅ ZemaSuccess(['HELLO', 'WORLD'])
```

---

### Filter Array

```dart
final schema = z.array(z.integer())
  .transform((list) => list.where((n) => n > 0).toList());

schema.parse([1, -2, 3, -4, 5]);
// ✅ ZemaSuccess([1, 3, 5])
```

---

### Aggregate Array

```dart
final sumSchema = z.array(z.integer())
  .transform((list) => list.fold<int>(0, (sum, n) => sum + n));

sumSchema.parse([1, 2, 3, 4, 5]);
// ✅ ZemaSuccess(15)
```

---

### Array to Map

```dart
final schema = z.array(z.object({
  'id': z.string(),
  'name': z.string(),
})).transform((list) {
  return {
    for (final item in list)
      item['id']: item['name'],
  };
});

schema.parse([
  {'id': 'a', 'name': 'Alice'},
  {'id': 'b', 'name': 'Bob'},
]);
// ✅ ZemaSuccess({'a': 'Alice', 'b': 'Bob'})
```

---

## Complex Transformations

### CSV String to List

```dart
final csvSchema = z.string()
  .transform((csv) => csv.split(',').map((s) => s.trim()).toList());

csvSchema.parse('apple, banana, orange');
// ✅ ZemaSuccess(['apple', 'banana', 'orange'])
```

---

### JSON String to Object

```dart
final jsonSchema = z.string()
  .transform((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>);

jsonSchema.parse('{"name": "Alice", "age": 30}');
// ✅ ZemaSuccess({'name': 'Alice', 'age': 30})
```

---

### Hex Color to Color Object

```dart
import 'package:flutter/material.dart';

final colorSchema = z.string()
  .regex(RegExp(r'^#[0-9A-Fa-f]{6}$'), 'Invalid hex color')
  .transform((hex) {
    final value = int.parse(hex.substring(1), radix: 16);
    return Color(0xFF000000 + value);
  });

colorSchema.parse('#FF5733');
// ✅ ZemaSuccess(Color(0xFFFF5733))
```

---

### Duration String to Duration

```dart
// Parse "1h 30m" to Duration
final durationSchema = z.string()
  .regex(RegExp(r'^\d+h\s+\d+m$'), 'Format: "1h 30m"')
  .transform((str) {
    final parts = str.split(' ');
    final hours = int.parse(parts[0].replaceAll('h', ''));
    final minutes = int.parse(parts[1].replaceAll('m', ''));
    return Duration(hours: hours, minutes: minutes);
  });

durationSchema.parse('2h 45m');
// ✅ ZemaSuccess(Duration(hours: 2, minutes: 45))
```

---

## Conditional Transformations

```dart
final schema = z.string().transform((value) {
  // Conditional transformation
  if (value.startsWith('http://')) {
    return value.replaceFirst('http://', 'https://');
  }
  return value;
});

schema.parse('http://example.com');
// ✅ ZemaSuccess('https://example.com')

schema.parse('https://example.com');
// ✅ ZemaSuccess('https://example.com') (unchanged)
```

---

## Transforms with Validation

Transforms happen **after** validation:

```dart
final schema = z.string()
  .min(3, 'Min 3 chars')           // 1. Validate
  .transform((s) => s.toUpperCase());  // 2. Transform

// Flow:
// 1. Validate: 'ab'.length >= 3? ❌ STOP
schema.parse('ab');
// ❌ ZemaFailure (Min 3 chars)

// Flow:
// 1. Validate: 'hello'.length >= 3? ✅
// 2. Transform: 'hello' → 'HELLO'
schema.parse('hello');
// ✅ ZemaSuccess('HELLO')
```

---

## Transform vs Coerce

### Coerce

Built-in type conversion **before** validation:

```dart
z.integer().coerce();

// Flow:
// 1. Coerce: '42' → 42
// 2. Validate: 42 is int? ✅
```

---

### Transform

Custom conversion **after** validation:

```dart
z.string().transform((s) => int.parse(s));

// Flow:
// 1. Validate: '42' is String? ✅
// 2. Transform: '42' → 42
```

---

## Error Handling in Transforms

### Safe Transform

```dart
final schema = z.string().transform((value) {
  try {
    return int.parse(value);
  } catch (e) {
    // Return fallback or throw
    return 0;  // Fallback
  }
});

schema.parse('abc');
// ✅ ZemaSuccess(0)  (fallback used)
```

---

### Validate Before Transform

```dart
// ✅ Good: Validate format first
final schema = z.string()
  .regex(RegExp(r'^\d+$'), 'Must be numeric')  // Validate
  .transform((s) => int.parse(s));              // Safe to parse

// ❌ Bad: No validation
final badSchema = z.string()
  .transform((s) => int.parse(s));  // 💥 Throws on 'abc'
```

---

## Real-World Examples

### API Response Normalization

```dart
// API returns inconsistent date formats
final dateSchema = z.union([
  z.string().datetime(),  // ISO 8601
  z.integer(),            // Timestamp
]).transform((value) {
  if (value is String) {
    return DateTime.parse(value);
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  throw ArgumentError('Invalid date format');
});

dateSchema.parse('2024-02-08T10:30:00Z');
// ✅ ZemaSuccess(DateTime(2024, 2, 8, 10, 30))

dateSchema.parse(1707389400000);
// ✅ ZemaSuccess(DateTime(2024, 2, 8, ...))
```

---

### Money Object

```dart
class Money {
  final double amount;
  final String currency;
  
  Money(this.amount, this.currency);
  
  @override
  String toString() => '$currency $amount';
}

final moneySchema = z.object({
  'amount': z.double(),
  'currency': z.string().length(3),  // USD, EUR, etc.
}).transform((map) => Money(
  map['amount'],
  map['currency'],
));

moneySchema.parse({'amount': 19.99, 'currency': 'USD'});
// ✅ ZemaSuccess(Money(19.99, 'USD'))
```

---

### Slug Generation

```dart
final slugSchema = z.string()
  .transform((title) {
    return title
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')  // Remove special chars
        .replaceAll(RegExp(r'\s+'), '-')      // Spaces to hyphens
        .replaceAll(RegExp(r'-+'), '-')       // Multiple hyphens to one
        .replaceAll(RegExp(r'^-|-$'), '');    // Remove leading/trailing
  });

slugSchema.parse('  Hello World! 123  ');
// ✅ ZemaSuccess('hello-world-123')
```

---

### Sanitize HTML

```dart
final htmlSchema = z.string()
  .transform((html) {
    // Remove script tags
    var sanitized = html.replaceAll(RegExp(r'<script[^>]*>.*?</script>'), '');
    
    // Remove event handlers
    sanitized = sanitized.replaceAll(RegExp(r'\son\w+\s*=\s*["\'][^"\']*["\']'), '');
    
    return sanitized;
  });

htmlSchema.parse('<div onclick="alert()">Hello</div>');
// ✅ ZemaSuccess('<div>Hello</div>')
```

---

### Normalize Phone Number

```dart
final phoneSchema = z.string()
  .transform((phone) {
    // Remove all non-digits
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    
    // Add country code if missing
    if (digitsOnly.length == 10) {
      return '+1$digitsOnly';  // US default
    }
    
    return '+$digitsOnly';
  });

phoneSchema.parse('(555) 123-4567');
// ✅ ZemaSuccess('+15551234567')
```

---

## Performance Considerations

### Avoid Heavy Computation

```dart
// ❌ Bad: Heavy computation on every validation
z.string().transform((s) {
  // Complex regex or database query
  return expensiveOperation(s);
});

// ✅ Better: Cache results
final _transformCache = <String, String>{};

z.string().transform((s) {
  if (_transformCache.containsKey(s)) {
    return _transformCache[s]!;
  }
  
  final result = expensiveOperation(s);
  _transformCache[s] = result;
  
  return result;
});
```

---

### Lazy Transformation

```dart
// ❌ Transform immediately
final schema = z.string()
  .transform((s) => s.split(',').map((e) => expensiveTransform(e)).toList());

// ✅ Transform lazily
final schema = z.string()
  .transform((s) => s.split(','))  // Cheap operation
  // Later: results.map(expensiveTransform) when needed
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Validate before transforming
z.string().regex(RegExp(r'^\d+$')).transform((s) => int.parse(s));

// ✅ Use clear transformations
.transform((s) => s.toUpperCase())  // Clear intent

// ✅ Handle errors in transforms
.transform((s) {
  try {
    return int.parse(s);
  } catch (e) {
    return 0;  // Fallback
  }
});

// ✅ Chain simple transforms
.transform((s) => s.trim())
.transform((s) => s.toLowerCase())
```

---

### ❌ DON'T

```dart
// ❌ Don't transform without validation
z.string().transform((s) => int.parse(s));  // 💥 Crashes on 'abc'

// ❌ Don't do validation in transforms
z.string().transform((s) {
  if (s.length < 8) throw 'Too short';  // ❌ Use .min(8) instead
  return s;
});

// ❌ Don't mutate original data
z.array(z.integer()).transform((list) {
  list.sort();  // ❌ Mutates original
  return list;
});
// Use: list.toList()..sort()

// ❌ Don't do heavy sync operations
.transform((s) => expensiveSyncOperation(s));  // Blocks UI
```

---

## API Reference

### transform

```dart
schema.transform<R>(R Function(T value) fn)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `fn` | `R Function(T)` | Transformation function |
| `<R>` | Type parameter | Result type after transformation |

**Returns:** `ZemaSchema<R>`

---

## Next Steps

- [Preprocess →](./preprocess) - Process data before validation
- [Coercion →](./coercion) - Automatic type conversion
- [Custom Types →](/docs/core/schemas/custom-types) - Define custom schemas
