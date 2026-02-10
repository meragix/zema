---
sidebar_position: 3
description: Automatically convert between types during validation
---

# Type Coercion

Zema can automatically convert (coerce) data from one type to another during validation.

---

## Why Coercion?

External data often comes in the wrong format:

```dart
// API returns numbers as strings
{
  "age": "30",        // ❌ String, not int
  "price": "19.99",   // ❌ String, not double
  "active": "true"    // ❌ String, not bool
}

// Form inputs are always strings
TextField(onChanged: (value) {
  // value is String, but you need int
});
```

**Coercion** automatically converts these types.

---

## Integer Coercion

### Basic Integer Coercion

```dart
final schema = z.integer().coerce();

schema.parse(42);      // ✅ ZemaSuccess(42)
schema.parse('42');    // ✅ ZemaSuccess(42)  (coerced from string)
schema.parse('  42  '); // ✅ ZemaSuccess(42)  (trimmed and parsed)
schema.parse('abc');   // ❌ ZemaFailure (cannot parse)
schema.parse('3.14');  // ❌ ZemaFailure (not an integer)
```

---

### Coercion Rules

```dart
final schema = z.integer().coerce();

// From String
schema.parse('123');    // ✅ 123
schema.parse('  123  '); // ✅ 123 (whitespace trimmed)
schema.parse('0');      // ✅ 0
schema.parse('-42');    // ✅ -42

// From int (passthrough)
schema.parse(123);      // ✅ 123

// From double (if whole number)
schema.parse(42.0);     // ✅ 42

// Invalid
schema.parse('12.5');   // ❌ Not an integer
schema.parse('abc');    // ❌ Cannot parse
schema.parse(true);     // ❌ Not coercible
```

---

## Double Coercion

### Basic Double Coercion

```dart
final schema = z.double().coerce();

schema.parse(3.14);     // ✅ ZemaSuccess(3.14)
schema.parse('3.14');   // ✅ ZemaSuccess(3.14)  (coerced)
schema.parse(42);       // ✅ ZemaSuccess(42.0)  (int → double)
schema.parse('42');     // ✅ ZemaSuccess(42.0)  (string → double)
schema.parse('abc');    // ❌ ZemaFailure
```

---

### Coercion Rules

```dart
final schema = z.double().coerce();

// From String
schema.parse('3.14');    // ✅ 3.14
schema.parse('  3.14  '); // ✅ 3.14 (whitespace trimmed)
schema.parse('0.0');     // ✅ 0.0
schema.parse('-42.5');   // ✅ -42.5

// From int
schema.parse(42);        // ✅ 42.0

// From double (passthrough)
schema.parse(3.14);      // ✅ 3.14

// Scientific notation
schema.parse('1.5e10');  // ✅ 15000000000.0

// Invalid
schema.parse('abc');     // ❌ Cannot parse
schema.parse(true);      // ❌ Not coercible
```

---

## Boolean Coercion

### Basic Boolean Coercion

```dart
final schema = z.boolean().coerce();

schema.parse(true);      // ✅ ZemaSuccess(true)
schema.parse('true');    // ✅ ZemaSuccess(true)  (coerced)
schema.parse(1);         // ✅ ZemaSuccess(true)  (coerced)
schema.parse('yes');     // ✅ ZemaSuccess(true)  (coerced)
schema.parse(false);     // ✅ ZemaSuccess(false)
schema.parse('0');       // ✅ ZemaSuccess(false)  (coerced)
```

---

### Coercion Rules

```dart
final schema = z.boolean().coerce();

// Truthy values → true
schema.parse(true);      // ✅ true
schema.parse('true');    // ✅ true
schema.parse('True');    // ✅ true (case-insensitive)
schema.parse('TRUE');    // ✅ true
schema.parse('yes');     // ✅ true
schema.parse('Yes');     // ✅ true
schema.parse('1');       // ✅ true
schema.parse(1);         // ✅ true

// Falsy values → false
schema.parse(false);     // ✅ false
schema.parse('false');   // ✅ false
schema.parse('False');   // ✅ false
schema.parse('FALSE');   // ✅ false
schema.parse('no');      // ✅ false
schema.parse('No');      // ✅ false
schema.parse('0');       // ✅ false
schema.parse(0);         // ✅ false

// Invalid
schema.parse('maybe');   // ❌ Unknown value
schema.parse(2);         // ❌ Not 0 or 1
```

---

## String Coercion

### Basic String Coercion

```dart
final schema = z.string().coerce();

schema.parse('hello');   // ✅ ZemaSuccess('hello')
schema.parse(42);        // ✅ ZemaSuccess('42')  (coerced)
schema.parse(true);      // ✅ ZemaSuccess('true')  (coerced)
schema.parse(3.14);      // ✅ ZemaSuccess('3.14')  (coerced)
```

---

### Coercion Rules

```dart
final schema = z.string().coerce();

// From String (passthrough)
schema.parse('hello');   // ✅ 'hello'

// From int
schema.parse(42);        // ✅ '42'

// From double
schema.parse(3.14);      // ✅ '3.14'

// From bool
schema.parse(true);      // ✅ 'true'
schema.parse(false);     // ✅ 'false'

// From null (if nullable)
z.string().coerce().nullable().parse(null);  // ✅ 'null'

// Objects (uses toString())
schema.parse(DateTime.now());  // ✅ '2024-02-08...'
```

---

## DateTime Coercion

### From ISO 8601 String

```dart
final schema = z.datetime().coerce();

schema.parse(DateTime.now());              // ✅ DateTime (passthrough)
schema.parse('2024-02-08T10:30:00Z');     // ✅ DateTime (parsed)
schema.parse('2024-02-08');                // ✅ DateTime (parsed)
schema.parse(1707389400000);               // ✅ DateTime (from milliseconds)
schema.parse('not-a-date');                // ❌ Invalid format
```

---

### Coercion Rules

```dart
final schema = z.datetime().coerce();

// From DateTime (passthrough)
schema.parse(DateTime.now());  // ✅ DateTime

// From ISO 8601 string
schema.parse('2024-02-08T10:30:00Z');      // ✅ DateTime
schema.parse('2024-02-08T10:30:00+01:00'); // ✅ DateTime (with timezone)
schema.parse('2024-02-08');                 // ✅ DateTime (date only)

// From milliseconds since epoch (int)
schema.parse(1707389400000);  // ✅ DateTime

// From seconds since epoch (transform first)
final secondsSchema = z.integer()
  .transform((seconds) => DateTime.fromMillisecondsSinceEpoch(seconds * 1000))
  .coerce();

// Invalid
schema.parse('invalid');  // ❌ Cannot parse
schema.parse(true);       // ❌ Not coercible
```

---

## Real-World Examples

### Form Input Validation

```dart
// All form inputs are strings
final formSchema = z.object({
  'name': z.string(),
  'age': z.integer().coerce().min(18),           // ✅ Coerce string → int
  'price': z.double().coerce().positive(),        // ✅ Coerce string → double
  'subscribe': z.boolean().coerce(),              // ✅ Coerce string → bool
  'birthDate': z.datetime().coerce(),             // ✅ Coerce string → DateTime
});

// Usage in Flutter
final result = formSchema.parse({
  'name': nameController.text,
  'age': ageController.text,        // '30' → 30
  'price': priceController.text,    // '19.99' → 19.99
  'subscribe': subscribeCheckbox,   // 'true' → true
  'birthDate': dateController.text, // '2000-01-15' → DateTime
});
```

---

### API Response with Inconsistent Types

```dart
// API sometimes returns numbers as strings
final productSchema = z.object({
  'id': z.integer().coerce(),       // Might be string or int
  'price': z.double().coerce(),      // Might be string or double
  'inStock': z.boolean().coerce(),   // Might be '1'/'0' or bool
});

// Handles both formats
productSchema.parse({
  'id': '123',      // ✅ Coerced to 123
  'price': '19.99', // ✅ Coerced to 19.99
  'inStock': '1',   // ✅ Coerced to true
});

productSchema.parse({
  'id': 123,        // ✅ Already int
  'price': 19.99,   // ✅ Already double
  'inStock': true,  // ✅ Already bool
});
```

---

### Query Parameters

```dart
// URL query params are always strings
final querySchema = z.object({
  'page': z.integer().coerce().min(1).default(1),
  'perPage': z.integer().coerce().min(1).max(100).default(20),
  'sortBy': z.string().default('date'),
  'ascending': z.boolean().coerce().default(true),
});

// Parse URL: /api/posts?page=2&perPage=50&ascending=false
final result = querySchema.parse({
  'page': '2',         // ✅ Coerced to 2
  'perPage': '50',     // ✅ Coerced to 50
  'ascending': 'false', // ✅ Coerced to false
  // sortBy omitted → uses default
});
```

---

### Environment Variables

```dart
// Environment variables are always strings
final envSchema = z.object({
  'PORT': z.integer().coerce().min(1).max(65535).default(8080),
  'DEBUG': z.boolean().coerce().default(false),
  'TIMEOUT_MS': z.integer().coerce().positive().default(5000),
  'API_URL': z.string().url(),
});

// Usage
final config = envSchema.parse({
  'PORT': Platform.environment['PORT'],           // '3000' → 3000
  'DEBUG': Platform.environment['DEBUG'],         // 'true' → true
  'TIMEOUT_MS': Platform.environment['TIMEOUT_MS'], // '10000' → 10000
  'API_URL': Platform.environment['API_URL'],
});
```

---

## Coercion with Validation

Coercion happens **before** validation:

```dart
final schema = z.integer().coerce().min(18).max(100);

// Flow:
// 1. Coerce: '25' → 25
// 2. Validate: 25 >= 18 ✅
// 3. Validate: 25 <= 100 ✅
schema.parse('25');  // ✅ ZemaSuccess(25)

// Flow:
// 1. Coerce: '15' → 15
// 2. Validate: 15 >= 18 ❌
schema.parse('15');  // ❌ ZemaFailure (too small)

// Flow:
// 1. Coerce: 'abc' → ❌ Cannot parse
schema.parse('abc');  // ❌ ZemaFailure (invalid format)
```

---

## Custom Coercion

### Transform for Custom Types

```dart
// Coerce CSV string to List
final csvSchema = z.string()
  .transform((csv) => csv.split(',').map((s) => s.trim()).toList());

csvSchema.parse('apple, banana, orange');
// ✅ ZemaSuccess(['apple', 'banana', 'orange'])

// Coerce seconds to Duration
final durationSchema = z.integer()
  .transform((seconds) => Duration(seconds: seconds));

durationSchema.parse(3600);
// ✅ ZemaSuccess(Duration(hours: 1))

// Coerce hex color to Color
final colorSchema = z.string()
  .regex(RegExp(r'^#[0-9A-Fa-f]{6}$'))
  .transform((hex) {
    final value = int.parse(hex.substring(1), radix: 16);
    return Color(0xFF000000 + value);
  });

colorSchema.parse('#FF5733');
// ✅ ZemaSuccess(Color(0xFFFF5733))
```

---

## Performance Considerations

### Coercion has Small Overhead

```dart
// Without coercion: ~50μs per validation
z.integer().parse(42);

// With coercion: ~70μs per validation
z.integer().coerce().parse('42');

// Overhead: ~20μs (negligible for most apps)
```

---

### When to Use Coercion

✅ **Use coercion when:**

- Parsing form inputs (always strings)
- Handling API inconsistencies (mixed types)
- Reading environment variables
- Processing URL query parameters

❌ **Don't use coercion when:**

- Data is already the correct type
- Type mismatch indicates a bug (should fail)
- You need strict type checking

---

## Coercion vs Transform

### Coercion

Built-in type conversion:

```dart
z.integer().coerce();  // String → int
z.boolean().coerce();  // String → bool
```

---

### Transform

Custom conversion logic:

```dart
z.string().transform((s) => s.toUpperCase());  // Custom logic
```

**Use coercion** for standard type conversions.  
**Use transform** for custom business logic.

---

## API Reference

| Method | Input Types | Output Type | Example |
|--------|-------------|-------------|---------|
| `z.integer().coerce()` | String, int, double | int | `'42'` → `42` |
| `z.double().coerce()` | String, int, double | double | `'3.14'` → `3.14` |
| `z.boolean().coerce()` | String, int, bool | bool | `'true'` → `true` |
| `z.string().coerce()` | String, int, double, bool | String | `42` → `'42'` |
| `z.datetime().coerce()` | String, DateTime, int | DateTime | `'2024-01-15'` → `DateTime` |

---

## Next Steps

- [Transforms →](./transforms) - Custom data transformations
- [Preprocess →](./preprocess) - Process data before validation
- [Custom Validators →](/docs/core/validation/custom-validators) - Write your own logic
