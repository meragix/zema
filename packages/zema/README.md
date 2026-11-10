# Zema

[![pub version](https://img.shields.io/pub/v/zema.svg)](https://pub.dev/packages/zema)
[![pub likes](https://img.shields.io/pub/likes/zema)](https://pub.dev/packages/zema/score)
[![pub points](https://img.shields.io/pub/points/zema)](https://pub.dev/packages/zema/score)
[![CI](https://github.com/meragix/zema/actions/workflows/zema.yml/badge.svg)](https://github.com/meragix/zema/actions/workflows/zema.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**Validate untrusted data in Dart and Flutter.** Describe the shape you expect once, then use that schema for API responses, forms, Firestore documents and local storage.

- **Every error, in one pass.** Each issue has a code, a translated message and the exact path (`items.[2].email`), ready to show next to a form field.
- **No build_runner.** Schemas are plain Dart values. Get typed models with extension types, or hand the validated map to your existing Freezed / json_serializable classes.
- **Runs everywhere.** Pure Dart, no dependencies besides `meta`: Flutter (mobile, desktop, **web**), server and CLI.
- **Familiar API.** If you know [Zod](https://zod.dev), you already know Zema: `z.object`, `z.string().email()`, `safeParse`, `refine`, `pipe`.

```dart
import 'dart:convert';

import 'package:zema/zema.dart';

// A typed view of the validated map. Zero runtime cost, no code generation.
extension type User(Map<String, dynamic> data) {
  int get id => data['id'] as int;
  String get email => data['email'] as String;
  String get role => data['role'] as String;
}

final userSchema = z.objectAs<User>(
  {
    'id': z.integer().positive(),
    'email': z.string().email(),
    'role': z.string().oneOf(['admin', 'member']),
    'nickname': z.string().min(2).optional(),
  },
  User.new,
);

void handle(String body) {
  final result = userSchema.safeParse(jsonDecode(body));

  switch (result) {
    case ZemaSuccess(:final value):
      print('Hello ${value.email}'); // value is a User
    case ZemaFailure(:final errors):
      for (final issue in errors) {
        print('${issue.pathString}: ${issue.message}');
      }
  }
}

// handle('{"id": -4, "email": "ada@", "role": "owner"}') prints:
//   id: Must be a positive number
//   email: Invalid email format
//   role: Must be one of: admin, member
```

## Why Zema?

`User.fromJson(json)` trusts its input. When the backend sends `"id": "42"`, a field disappears, or an old app version wrote a bad Firestore document, you get a `TypeError` at the first bad field, far from where the data came in, with nothing you can show the user.

Zema checks the data at the boundary and tells you **everything** that is wrong, with paths and human-readable messages (built in: English and French, add your own).

### What about Freezed or json_serializable?

They generate models; they do not validate values (`email` is a `String`, not a valid email; `age` is an `int`, not "18 or more"). Zema covers that layer and composes with them:

```dart
// Validate first, then build your Freezed / json_serializable model
// from clean data. mapTo only runs on success.
final profile = z.object({
  'email': z.string().email(),
  'age': z.integer().gte(18),
}).safeParse(json).mapTo(Profile.fromJson);
```

If you would rather not run `build_runner` at all, `z.objectAs` plus an extension type (as above) gives you typed access with no generated code.

## Ecosystem

| Package | Use it to |
| --- | --- |
| [`zema`](https://pub.dev/packages/zema) | Define and run schemas (this package) |
| [`zema_forms`](https://pub.dev/packages/zema_forms) | Drive Flutter forms from a schema: per-field rebuilds, errors on blur, focus on the first error |
| [`zema_firestore`](https://pub.dev/packages/zema_firestore) | Validate every Firestore read through `withConverter`, with `Timestamp` and `GeoPoint` schemas |
| [`zema_hive`](https://pub.dev/packages/zema_hive) | Validate Hive CE reads and writes, migrate old documents on read, no TypeAdapters |
| [`zema_standard_schema`](https://pub.dev/packages/zema_standard_schema) | Expose any schema through the [Standard Schema](https://pub.dev/packages/standard_schema) contract |

## Installation

```sh
dart pub add zema
```

```dart
import 'package:zema/zema.dart';
```

Requires Dart 3.5 or later.

## Guide

### Primitives

```dart
final name = z.string().trim().min(2).max(50);
final email = z.string().email();
final website = z.string().url();
final id = z.string().uuid();
final zip = z.string().regex(RegExp(r'^\d{5}$'));
final status = z.string().oneOf(['draft', 'published']);

final age = z.integer().gte(0).lte(120);
final quantity = z.integer().positive(); // > 0
final step = z.integer().step(5); // multiple of 5
final ratio = z.double().gte(0).lte(1);

final accepted = z.boolean();
final createdAt = z.dateTime();
final kind = z.literal('admin');
```

### Objects

```dart
final account = z.object({
  'id': z.string().uuid(),
  'email': z.string().email(),
  'password': z.string().min(8),
  'nickname': z.string().optional(), // may be absent or null
});

final strict = account.makeStrict(); // unknown keys become errors
final withRole = account.extend({'role': z.string()});
final public = account.omit(['password']);
final login = account.pick(['email', 'password']);
final merged = account.merge(z.object({'plan': z.string()}));
```

`z.object()` produces a `Map<String, dynamic>`. Use `z.objectAs<T>(shape, constructor)` to get a typed value, as in the example at the top.

### Arrays, maps, unions

```dart
final tags = z.array(z.string()).min(1).max(10);
final scores = z.map(z.string(), z.integer().gte(0));

final idOrSlug = z.union<dynamic>([z.integer().positive(), z.string()]);

// Discriminated union: picks the branch from the 'type' field directly.
final event = z.union([
  z.object({'type': z.literal('click'), 'x': z.integer(), 'y': z.integer()}),
  z.object({'type': z.literal('key'), 'key': z.string()}),
]).discriminatedBy('type');
```

### Optional, nullable, default, fallback

```dart
final nickname = z.string().optional(); // null passes through
final middleName = z.string().nullable(); // null is a valid value
final page = z.integer().withDefault(1); // null becomes 1
final safeCount = z.integer().catchError((issues) => 0); // never fails
```

### Transform, pipe, preprocess

```dart
// Change the output after validation.
final upper = z.string().transform((s) => s.toUpperCase());

// Feed the output into another schema.
final percent = z.string().transform(int.parse).pipe(z.integer().gte(0).lte(100));

// Clean the raw input before validation.
final trimmedEmail = z.string().email().preprocess<dynamic>(
      (v) => v?.toString().trim(),
    );
```

### Coercion (env vars, query strings, text fields)

```dart
final port = z.coerce().integer(min: 1, max: 65535); // '8080' -> 8080
final debug = z.coerce().boolean(); // 'true', '1' -> true
final price = z.coerce().float(); // '9.99' -> 9.99
final since = z.coerce().dateTime(); // ISO string or Unix ms -> DateTime
```

### Custom rules

```dart
final https = z.string().url().refine(
      (s) => s.startsWith('https://'),
      message: 'Must use HTTPS.',
    );

final password = z.string().min(8).superRefine((value, ctx) {
  if (!value.contains(RegExp('[A-Z]'))) {
    ctx.addIssue(code: 'missing_uppercase', message: 'Add an uppercase letter.');
  }
  if (!value.contains(RegExp('[0-9]'))) {
    ctx.addIssue(code: 'missing_digit', message: 'Add a digit.');
  }
  return null;
});

// Async checks (database, network) run with safeParseAsync / parseAsync.
final username = z.string().refineAsync(
      (name) async => name != 'taken',
      message: 'Username already taken.',
    );
final check = await username.safeParseAsync('ada');
```

### Errors

```dart
final result = account.safeParse({'email': 'nope'});

if (result.isFailure) {
  for (final issue in result.errors) {
    // issue.code: 'invalid_email', 'too_short', 'required', ...
    // issue.path: ['email']
    // issue.message: translated, human-readable text
    print('[${issue.code}] ${issue.pathString}: ${issue.message}');
  }

  // Nested map for form UIs: {email: {_errors: [Invalid email format]}, ...}
  final byField = result.errors.format();
}

// parse() throws instead of returning a result.
try {
  account.parse({'email': 'nope'});
} on ZemaException catch (e) {
  print(e.issues.length);
}
```

### Messages and languages

```dart
ZemaErrorMap.setLocale('fr'); // built in: 'en' (default), 'fr'

// Add a language. Missing codes fall back to English.
ZemaI18n.registerTranslations('es', {
  'invalid_email': (_) => 'Correo electrónico no válido.',
  'too_short': (p) => 'Mínimo ${p?['min']} caracteres.',
});

// Override a message globally. Return null to keep the default.
ZemaErrorMap.setErrorMap((issue, ctx) {
  if (issue.code == 'invalid_email') return 'Please enter a valid email.';
  return null;
});

// Or per schema.
final contact = z.string().email(message: 'We need a valid email.');
```

### Branded types

```dart
abstract class UserIdBrand {}

final userId = z.string().uuid().brand<UserIdBrand>();
final Branded<String, UserIdBrand> id = userId.parse(
  '550e8400-e29b-41d4-a716-446655440000',
);
// A plain String or another brand can no longer be passed where a
// Branded<String, UserIdBrand> is expected.
```

### Recursive and custom schemas

```dart
late final ZemaSchema<dynamic, Map<String, dynamic>> category;
category = z.object({
  'name': z.string(),
  'children': z.array(z.lazy(() => category)).optional(),
});

final token = z.custom<String>(
  (value) => value.startsWith('tok_'),
  message: 'Must be an API token.',
);
```

## Platform notes

- **Web:** fully supported. On the web, Dart numbers are JavaScript numbers, so `1.0 is int` is true and `z.integer()` accepts `1.0`. `parseInIsolate()` runs on the main thread there (isolates are not available).
- **Isolates:** on native platforms, `schema.parseInIsolate(value)` offloads large payloads to a background isolate. Schemas with closures (`refine`, `transform`) cannot cross isolates; use `Isolate.run(() => schema.safeParse(value))` for those.

## Performance

Validation costs microseconds per call, which is negligible next to JSON decoding or a network round trip. Zema is not the fastest validator on pub.dev. In the [benchmark](https://github.com/meragix/zema/tree/main/benchmark) below, acanthis is about twice as fast on strings and objects. Lower is better.

| Scenario (µs per call) | zema | acanthis | ez_validator | luthor | zard |
| --- | ---: | ---: | ---: | ---: | ---: |
| `String.email` | 6.77 | 3.05 | 6.93 | 10.67 | 9.21 |
| `Integer.range` | 0.14 | 0.46 | 0.31 | 0.54 | 1.87 |
| Object, 4 valid fields | 12.78 | 5.60 | 14.50 | 18.68 | 21.41 |
| Object, 3 invalid fields | 19.20 | 8.63 | 11.77 | 33.21 | 146.44 |

Dart 3.13 AOT (`dart compile exe`), Intel Core i9-9980HK, schemas built once and reused. Run it yourself with `make bench`. Performance work is tracked in [#10](https://github.com/meragix/zema/issues/10); contributions are welcome.

## Documentation

Guides, API reference and recipes: **[zema.meragix.dev](https://zema.meragix.dev)**. Coming from TypeScript? Read [Coming from Zod](https://zema.meragix.dev/getting-started/coming-from-zod).

## Contributing and support

- Found a bug or a confusing error message? [Open an issue](https://github.com/meragix/zema/issues).
- Want to help? See [CONTRIBUTING.md](https://github.com/meragix/zema/blob/main/CONTRIBUTING.md).
- If Zema saves you time, a **like on [pub.dev](https://pub.dev/packages/zema)** and a **star on [GitHub](https://github.com/meragix/zema)** help other developers find it.

MIT License.
