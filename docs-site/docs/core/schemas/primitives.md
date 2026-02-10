---
sidebar_position: 1
description: Learn about Zema's primitive schema types - string, integer, double, boolean
---

# Primitive Types

Zema provides schemas for all Dart primitive types.

---

## String

### Basic String

```dart
final schema = z.string();

schema.parse('hello');        // ✅ ZemaSuccess('hello')
schema.parse(123);            // ❌ ZemaFailure (not a string)
schema.parse(null);           // ❌ ZemaFailure (required)
```

---

### String Validators

#### Length Constraints

```dart
// Minimum length
z.string().min(5);

schema.parse('hello');        // ✅ (length = 5)
schema.parse('hi');           // ❌ Too short

// Maximum length
z.string().max(10);

schema.parse('hello');        // ✅ (length = 5)
schema.parse('hello world!'); // ❌ Too long

// Exact length
z.string().length(5);

schema.parse('hello');        // ✅
schema.parse('hi');           // ❌ Not exactly 5 chars
```

---

#### Format Validators

```dart
// Email
z.string().email();

schema.parse('alice@example.com');  // ✅
schema.parse('not-an-email');       // ❌

// URL
z.string().url();

schema.parse('https://example.com'); // ✅
schema.parse('not a url');           // ❌

// UUID
z.string().uuid();

schema.parse('550e8400-e29b-41d4-a716-446655440000'); // ✅
schema.parse('not-a-uuid');                           // ❌

// Regex
z.string().regex(RegExp(r'^\d{3}-\d{2}-\d{4}$'));

schema.parse('123-45-6789');  // ✅
schema.parse('invalid');       // ❌
```

---

#### Trim & Transform

```dart
// Remove whitespace
z.string().trim();

schema.parse('  hello  ');  // ✅ ZemaSuccess('hello')

// Convert to uppercase
z.string().transform((s) => s.toUpperCase());

schema.parse('hello');  // ✅ ZemaSuccess('HELLO')

// Convert to lowercase
z.string().transform((s) => s.toLowerCase());

schema.parse('HELLO');  // ✅ ZemaSuccess('hello')
```

---

### Custom String Messages

```dart
z.string()
  .min(5, 'Username must be at least 5 characters')
  .max(20, 'Username cannot exceed 20 characters')
  .regex(
    RegExp(r'^[a-zA-Z0-9_]+$'),
    'Username can only contain letters, numbers, and underscores',
  );
```

---

## Integer

### Basic Integer

```dart
final schema = z.integer();

schema.parse(42);         // ✅ ZemaSuccess(42)
schema.parse(3.14);       // ❌ ZemaFailure (not an integer)
schema.parse('42');       // ❌ ZemaFailure (not an integer)
```

---

### Integer Validators

```dart
// Minimum value
z.integer().min(0);

schema.parse(5);   // ✅
schema.parse(-1);  // ❌ Too small

// Maximum value
z.integer().max(100);

schema.parse(50);   // ✅
schema.parse(150);  // ❌ Too large

// Range
z.integer().min(0).max(100);

schema.parse(50);   // ✅
schema.parse(-1);   // ❌ Too small
schema.parse(150);  // ❌ Too large

// Positive only
z.integer().positive();  // Equivalent to .min(1)

// Non-negative
z.integer().nonNegative();  // Equivalent to .min(0)

// Negative only
z.integer().negative();  // Equivalent to .max(-1)
```

---

### Integer Coercion

```dart
// Convert strings to integers
final schema = z.integer().coerce();

schema.parse('42');   // ✅ ZemaSuccess(42)
schema.parse(42);     // ✅ ZemaSuccess(42)
schema.parse('abc');  // ❌ Cannot parse
```

---

## Double

### Basic Double

```dart
final schema = z.double();

schema.parse(3.14);   // ✅ ZemaSuccess(3.14)
schema.parse(42);     // ✅ ZemaSuccess(42.0)  (int → double)
schema.parse('3.14'); // ❌ ZemaFailure
```

---

### Double Validators

```dart
// Minimum value
z.double().min(0.0);

schema.parse(5.5);   // ✅
schema.parse(-1.0);  // ❌ Too small

// Maximum value
z.double().max(100.0);

schema.parse(50.5);   // ✅
schema.parse(150.0);  // ❌ Too large

// Positive only
z.double().positive();

// Finite only (no infinity/NaN)
z.double().finite();

schema.parse(3.14);              // ✅
schema.parse(double.infinity);   // ❌ Not finite
schema.parse(double.nan);        // ❌ Not finite
```

---

### Double Coercion

```dart
// Convert strings to doubles
final schema = z.double().coerce();

schema.parse('3.14');  // ✅ ZemaSuccess(3.14)
schema.parse(3.14);    // ✅ ZemaSuccess(3.14)
schema.parse('abc');   // ❌ Cannot parse
```

---

## Boolean

### Basic Boolean

```dart
final schema = z.boolean();

schema.parse(true);    // ✅ ZemaSuccess(true)
schema.parse(false);   // ✅ ZemaSuccess(false)
schema.parse(1);       // ❌ ZemaFailure
schema.parse('true');  // ❌ ZemaFailure
```

---

### Boolean Coercion

```dart
// Convert to boolean
final schema = z.boolean().coerce();

schema.parse(true);      // ✅ ZemaSuccess(true)
schema.parse('true');    // ✅ ZemaSuccess(true)
schema.parse('false');   // ✅ ZemaSuccess(false)
schema.parse(1);         // ✅ ZemaSuccess(true)
schema.parse(0);         // ✅ ZemaSuccess(false)
schema.parse('yes');     // ✅ ZemaSuccess(true)
schema.parse('no');      // ✅ ZemaSuccess(false)
```

Coercion rules:

- `true`, `'true'`, `'yes'`, `'1'`, `1` → `true`
- `false`, `'false'`, `'no'`, `'0'`, `0` → `false`
- Everything else → validation error

---

## DateTime

### Basic DateTime

```dart
final schema = z.datetime();

schema.parse(DateTime.now());           // ✅ ZemaSuccess(DateTime)
schema.parse('2024-01-15T10:30:00Z');  // ❌ ZemaFailure (string)
```

---

### DateTime from ISO 8601 String

```dart
// Parse ISO 8601 strings
final schema = z.string().datetime();

schema.parse('2024-01-15T10:30:00Z');     // ✅ Validates format
schema.parse('2024-01-15');               // ✅ Valid ISO 8601
schema.parse('not-a-date');               // ❌ Invalid format
```

Transform to DateTime:

```dart
final schema = z.string()
  .datetime()
  .transform((str) => DateTime.parse(str));

final result = schema.parse('2024-01-15T10:30:00Z');
// result.value is DateTime
```

---

### DateTime Validators

```dart
// After a specific date
z.datetime().after(DateTime(2024, 1, 1));

schema.parse(DateTime(2024, 6, 1));   // ✅
schema.parse(DateTime(2023, 6, 1));   // ❌ Too early

// Before a specific date
z.datetime().before(DateTime(2025, 1, 1));

schema.parse(DateTime(2024, 6, 1));   // ✅
schema.parse(DateTime(2025, 6, 1));   // ❌ Too late

// Between two dates
z.datetime()
  .after(DateTime(2024, 1, 1))
  .before(DateTime(2025, 1, 1));
```

---

## Null

### Explicit Null

```dart
final schema = z.null_();

schema.parse(null);   // ✅ ZemaSuccess(null)
schema.parse('abc');  // ❌ ZemaFailure
```

Rarely used directly. Usually combined with `.nullable()`:

```dart
z.string().nullable();  // String OR null
```

---

## Combining Primitives

### Chaining Validators

```dart
final usernameSchema = z.string()
  .min(3, 'Minimum 3 characters')
  .max(20, 'Maximum 20 characters')
  .regex(
    RegExp(r'^[a-zA-Z0-9_]+$'),
    'Only letters, numbers, and underscores',
  )
  .transform((s) => s.toLowerCase());

usernameSchema.parse('Alice_123');  // ✅ ZemaSuccess('alice_123')
usernameSchema.parse('Al');         // ❌ Too short
usernameSchema.parse('Alice@123');  // ❌ Invalid characters
```

---

### Default Values

```dart
final schema = z.integer().default(0);

schema.parse(42);    // ✅ ZemaSuccess(42)
schema.parse(null);  // ✅ ZemaSuccess(0)  (uses default)
```

---

### Optional vs Nullable

```dart
// Optional: can be null OR undefined
z.string().optional();

schema.parse('hello');  // ✅ ZemaSuccess('hello')
schema.parse(null);     // ✅ ZemaSuccess(null)

// Nullable: can be null but NOT undefined
z.string().nullable();

schema.parse('hello');  // ✅ ZemaSuccess('hello')
schema.parse(null);     // ✅ ZemaSuccess(null)
```

[→ Learn more about optional/nullable](/docs/core/schemas/optional-nullable)

---

## Real-World Examples

### User Registration

```dart
final registrationSchema = z.object({
  'username': z.string()
    .min(3)
    .max(20)
    .regex(RegExp(r'^[a-zA-Z0-9_]+$')),
    
  'email': z.string().email(),
  
  'password': z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(
      RegExp(r'(?=.*[0-9])'),
      'Password must contain at least one number',
    ),
    
  'age': z.integer()
    .min(18, 'Must be 18 or older')
    .optional(),
});
```

---

### Product Schema

```dart
final productSchema = z.object({
  'id': z.string().uuid(),
  'name': z.string().min(1).max(200),
  'price': z.double().positive(),
  'discount': z.double().min(0.0).max(1.0).optional(),
  'inStock': z.boolean().default(true),
  'createdAt': z.string().datetime(),
});
```

---

## API Reference

### String Methods

| Method | Description |
|--------|-------------|
| `.min(n)` | Minimum length |
| `.max(n)` | Maximum length |
| `.length(n)` | Exact length |
| `.email()` | Valid email |
| `.url()` | Valid URL |
| `.uuid()` | Valid UUID |
| `.regex(r)` | Matches regex |
| `.trim()` | Remove whitespace |
| `.datetime()` | ISO 8601 format |

### Integer Methods

| Method | Description |
|--------|-------------|
| `.min(n)` | Minimum value |
| `.max(n)` | Maximum value |
| `.positive()` | > 0 |
| `.negative()` | < 0 |
| `.nonNegative()` | ≥ 0 |
| `.coerce()` | Parse from string |

### Double Methods

| Method | Description |
|--------|-------------|
| `.min(n)` | Minimum value |
| `.max(n)` | Maximum value |
| `.positive()` | > 0.0 |
| `.finite()` | No infinity/NaN |
| `.coerce()` | Parse from string |

---

## Next Steps

- [Arrays →](./arrays) - Validate lists
- [Objects →](./objects) - Validate maps
- [Validation →](/docs/core/validation/basic-validation) - How to use schemas
