# Zema

[![pub package](https://img.shields.io/pub/v/zema.svg)](https://pub.dev/packages/zema)
[![package publisher](https://img.shields.io/pub/publisher/zema.svg)](https://pub.dev/packages/zema/publisher)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Schema validation for Dart, inspired by [Zod](https://zod.dev). Define schemas once, validate anywhere. All validation errors are collected in a single pass — no silent failures, no partial results.

---

## Features

- Fluent, chainable API: `z.string().min(2).email()`
- Exhaustive error collection: every failing field is reported, not just the first
- Sealed result type: `ZemaSuccess<T>` and `ZemaFailure<T>` — no exceptions by default
- Composable objects: `extend()`, `merge()`, `pick()`, `omit()`
- Discriminated unions with O(1) schema selection
- Async refinements for database and network checks
- Coercion for environment variables and query parameters
- Nominal branding for type-safe IDs
- Built-in i18n with `en` and `fr` locales; extensible to any locale

---

## Installation

```yaml
dependencies:
  zema: ^0.3.0
```

```dart
import 'package:zema/zema.dart';
```

---

## Quick start

```dart
final userSchema = z.object({
  'name':  z.string().min(2),
  'email': z.string().email(),
  'age':   z.integer().gte(18).optional(),
});

// parse() returns the validated value or throws ZemaException
final user = userSchema.parse({
  'name':  'Alice',
  'email': 'alice@example.com',
});

// safeParse() never throws — returns ZemaResult<T>
final result = userSchema.safeParse(rawInput);

switch (result) {
  case ZemaSuccess(:final value):
    print(value['name']);
  case ZemaFailure(:final errors):
    for (final issue in errors) {
      print('${issue.path.join(".")}: ${issue.message}');
    }
}
```

---

## Primitives

```dart
z.string()         // String
z.integer()        // int
z.double()         // double
z.boolean()        // bool
z.dateTime()       // DateTime
z.literal('admin') // exact value
```

### String constraints

```dart
z.string().min(2).max(100)
z.string().email()
z.string().url()
z.string().uuid()
z.string().regex(RegExp(r'^\d{5}$'))
z.string().trim().min(1)
z.string().oneOf(['draft', 'published', 'archived'])
```

### Number constraints

```dart
z.integer().gte(0).lte(120)
z.integer().positive()      // > 0
z.integer().negative()      // < 0
z.integer().nonNegative()   // >= 0
z.integer().step(5)         // multiple of 5

z.double().gte(0.0).lte(1.0)
z.double().nonNegative()
z.double().finite()
```

---

## Objects

```dart
final schema = z.object({
  'id':       z.string().uuid(),
  'name':     z.string().min(2),
  'email':    z.string().email(),
  'password': z.string().min(8),
});

// Reject unknown keys
final strict = schema.makeStrict();

// Add fields
final extended = schema.extend({'role': z.string()});

// Merge two schemas (fields from other win on conflict)
final merged = base.merge(override);

// Subset of fields
final public = schema.pick(['id', 'name', 'email']);
final safe   = schema.omit(['password']);
```

### Typed output

```dart
final schema = z.objectAs(
  {'name': z.string(), 'age': z.integer()},
  (map) => User(name: map['name'] as String, age: map['age'] as int),
);

final User user = schema.parse(data);
```

---

## Arrays

```dart
z.array(z.string())
z.array(z.integer()).min(1).max(100)
z.array(z.string().email()).nonEmpty()
z.array(z.string()).length(3)

// All element errors collected in one pass, with index in error path
z.array(z.object({'email': z.string().email()}))
```

---

## Unions

```dart
// Linear scan: first matching schema wins
final id = z.union<dynamic>([
  z.string().uuid(),
  z.integer().positive(),
]);

// Discriminated union: O(1) lookup via literal field
final event = z.union([
  z.object({'type': z.literal('click'),    'x': z.integer(), 'y': z.integer()}),
  z.object({'type': z.literal('keypress'), 'key': z.string()}),
]).discriminatedBy('type');

event.parse({'type': 'click', 'x': 100, 'y': 200});
```

---

## Modifiers

```dart
z.string().optional()             // String?  — null passes through
z.string().nullable()             // String?  — null is a valid value
z.integer().withDefault(0)        // always returns a value, never null
z.integer().catchError((_) => 0)  // intercept failures, inspect issues

// Nominal branding: prevent mixing semantically different IDs
abstract class _UserIdBrand {}
abstract class _TeamIdBrand {}

final userIdSchema = z.string().uuid().brand<_UserIdBrand>();
final teamIdSchema = z.string().uuid().brand<_TeamIdBrand>();

final userId = userIdSchema.parse('550e8400-…'); // Branded<String, _UserIdBrand>
// greet(teamId); // compile-time error
```

---

## Transformations

```dart
// .transform() changes the output type
final schema = z.string().transform(int.parse); // output: int

// .pipe() passes one schema's output into another
final piped = z.string().pipe(z.integer());

// .preprocess() normalises raw input before validation
final schema = z.preprocess(
  (v) => v.toString().trim(),
  z.string().email(),
);
```

---

## Refinements

```dart
// Single boolean check
z.string().refine(
  (s) => s.startsWith('https'),
  message: 'Must use HTTPS.',
);

// Multiple issues from one check
z.string().superRefine((s, ctx) {
  final issues = <ZemaIssue>[];
  if (!s.contains(RegExp(r'[A-Z]'))) {
    issues.add(ZemaIssue(code: 'missing_uppercase', message: 'Needs an uppercase letter.'));
  }
  if (!s.contains(RegExp(r'[0-9]'))) {
    issues.add(ZemaIssue(code: 'missing_digit', message: 'Needs a digit.'));
  }
  return issues.isEmpty ? null : issues;
});

// Async check (database lookup, API call)
final schema = z.string().email().refineAsync(
  (email) async => !(await db.emailExists(email)),
  message: 'Email already taken.',
);

final result = await schema.safeParseAsync(input);
```

---

## Coercion

Parse strings from environment variables, query parameters, or form inputs:

```dart
z.coerce().integer()  // '42' → 42
z.coerce().double()   // '3.14' → 3.14
z.coerce().boolean()  // 'true' | '1' → true
z.coerce().string()   // any → String
```

---

## Error handling

```dart
// safeParse: sealed result, never throws
final result = schema.safeParse(input);

if (result.isFailure) {
  for (final issue in result.errors) {
    // issue.code    — machine-readable string ('invalid_type', 'too_short', …)
    // issue.message — human-readable string
    // issue.path    — location in the input (['user', 'email'])
    print('[${issue.code}] ${issue.path.join(".")}: ${issue.message}');
  }
}

// parse: throws ZemaException on failure
try {
  final value = schema.parse(input);
} on ZemaException catch (e) {
  print(e.issues.map((i) => i.message).join(', '));
}
```

---

## i18n

```dart
// Built-in locales: 'en' (default), 'fr'
ZemaErrorMap.setLocale('fr');

// Custom locale
ZemaI18n.registerTranslations('es', {
  'invalid_type': 'Tipo inválido: se esperaba {expected}, se recibió {received}.',
  'too_short':    'Demasiado corto: mínimo {min}.',
  'too_long':     'Demasiado largo: máximo {max}.',
  'invalid_email': 'Dirección de correo inválida.',
});
ZemaErrorMap.setLocale('es');

// Custom error map for per-schema overrides
ZemaErrorMap.setErrorMap((code, ctx) {
  if (code == 'invalid_type' && ctx?['expected'] == 'string') {
    return 'A text value is required.';
  }
  return null; // fall back to locale default
});
```

---

## Custom schemas

```dart
final tokenSchema = z.custom<String>(
  (value) => value is String && value.startsWith('tok_'),
  message: 'Must be a valid token.',
);
```

---

## Documentation

Full guides, API reference, and examples: [zema.meragix.dev](https://zema.meragix.dev)

---

## License

MIT License — see [LICENSE](https://github.com/meragix/zema/blob/main/LICENSE)
