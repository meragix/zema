---
title: FAQ
description: Frequently asked questions about Zema.
seo:
  title: FAQ | Zema Docs
  description: Answers to the most common questions about Zema schema validation for Dart and Flutter.
---

## What is the difference between `parse()` and `safeParse()`?

`parse()` returns the validated value directly or throws a `ZemaException` containing all collected issues. Use it when a validation failure is a programming error or an unrecoverable state.

`safeParse()` never throws. It returns a sealed `ZemaResult<T>` : either `ZemaSuccess<T>` or `ZemaFailure<T>`. Use it whenever validation failure is an expected outcome (form input, API response, user data).

```dart
// parse: throws on failure
final user = userSchema.parse(input);

// safeParse: returns a result, never throws
final result = userSchema.safeParse(input);
if (result.isFailure) {
  showErrors(result.errors);
}
```

---

## Does Zema work with Flutter?

Yes. Zema is a pure Dart library with no Flutter dependencies. It works in Flutter apps, Dart Frog backends, CLI tools, and any other Dart environment.

---

## Why does the error path look like `['email', 'user']` instead of `['user', 'email']`?

Paths are built bottom-up. When `ZemaObject` validates the `user` field, the inner schema produces an issue with path `['email']`. The object then appends its own key: `[...childPath, 'user']`, giving `['email', 'user']`.

Reading from first to last: leaf segment first, root segment last. Use `path.reversed` or `pathString` for a top-down display.

---

## What is the difference between `optional()` and `nullable()`?

Both allow `null` to pass through. The distinction is semantic:

- `.optional()` is for fields that may be **absent** : a JSON key that is not always present. The null signals "not provided".
- `.nullable()` is for fields where `null` is a **meaningful value** : explicitly set to null by the caller.

In a `ZemaObject`, missing keys arrive as `null`, so both behave the same mechanically. The difference is a communication convention for readers of the schema.

---

## What is the difference between `withDefault()` and `catchError()`?

`.withDefault(value)` substitutes a static fallback for both `null` input and any validation failure. The failure is silently discarded.

`.catchError(fn)` also substitutes a fallback on failure, but calls `fn` with the list of `ZemaIssue`s first. Use it when you need to log, inspect, or compute the fallback based on the specific errors.

```dart
// Static fallback : error is discarded
z.integer().withDefault(0)

// Dynamic fallback : handler receives the issues
z.integer().catchError((issues) {
  logger.warn(issues.first.message);
  return 0;
})
```

---

## Can I reuse a schema across multiple objects?

Yes. Schemas are immutable values. Define them once at the top level and reference them from any other schema.

```dart
final emailSchema = z.string().email();
final ageSchema   = z.integer().gte(18);

final userSchema  = z.object({'email': emailSchema, 'age': ageSchema});
final adminSchema = userSchema.extend({'role': z.string()});
```

---

## How do I validate a list of objects?

Pass the list to `z.array()` with an object schema as the element schema. All element errors are collected in a single pass, each with the element index in the path.

```dart
final schema = z.array(z.object({
  'id':    z.integer().positive(),
  'email': z.string().email(),
}));

final result = schema.safeParse(jsonList);
```

---

## How do I validate a field that can be one of several types?

Use `z.union()`. Schemas are tried in order and the first match wins.

```dart
final idSchema = z.union<dynamic>([
  z.string().uuid(),
  z.integer().positive(),
]);
```

When all schemas share a common structure with a type discriminator, use `.discriminatedBy()` for direct O(1) lookup instead of a linear scan.

---

## How do I produce a typed class instead of `Map<String, dynamic>`?

Use `z.objectAs()` and provide a constructor function:

```dart
final schema = z.objectAs(
  {'name': z.string(), 'age': z.integer()},
  (map) => User(name: map['name'] as String, age: map['age'] as int),
);

final User user = schema.parse(data);
```

Alternatively, wrap the validated map in an extension type for zero allocation cost. See [Extension Types](/core/extension-types/what-are-extension-types).

---

## How do I validate environment variables or query parameters?

Use `z.coerce()`. It converts strings and compatible types before validation runs.

```dart
final port = z.coerce().integer().gte(1).lte(65535);
port.parse(Platform.environment['PORT'] ?? '8080'); // int
```

---

## How do I check uniqueness against a database?

Use `.refineAsync()`:

```dart
final schema = z.string().email().refineAsync(
  (email) async => !(await db.emailExists(email)),
  message: 'Email already taken.',
);

final result = await schema.safeParseAsync(input);
```

Run all synchronous validation first. `refineAsync` is only reached if the synchronous checks pass.

---

## How do I change the validation error language?

Set the locale via `ZemaErrorMap`:

```dart
ZemaErrorMap.setLocale('fr'); // built-in: 'en', 'fr'
```

Register a custom locale:

```dart
ZemaI18n.registerTranslations('es', {
  'invalid_type': 'Tipo inválido: se esperaba {expected}.',
  'too_short':    'Demasiado corto: mínimo {min}.',
});
ZemaErrorMap.setLocale('es');
```

---

## How do I write a custom schema?

Use `z.custom()` for a simple predicate:

```dart
final tokenSchema = z.custom<String>(
  (v) => v is String && v.startsWith('tok_'),
  message: 'Must be a valid token.',
);
```

For more complex behaviour, extend `ZemaSchema` directly and implement `safeParse`.

---

## Is there a performance cost to defining schemas at module scope?

No. Schemas are lightweight immutable objects. Defining them once at module scope is the recommended pattern : it avoids rebuilding schema instances on every call and is the single most impactful performance optimisation. See [Performance](/core/advanced/performance).

---

## Does Zema support recursive schemas?

Yes. Use `z.lazy()` to defer schema construction:

```dart
final nodeSchema = z.object({
  'value':    z.integer(),
  'children': z.array(z.lazy(() => nodeSchema)).optional(),
});
```

---

## Where do I report a bug or request a feature?

Open an issue on [GitHub](https://github.com/meragix/zema/issues). Include the Dart SDK version, Zema version, a minimal reproducible example, and the expected vs actual behaviour.
