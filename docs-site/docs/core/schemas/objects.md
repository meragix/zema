---
sidebar_position: 3
description: Validate objects and nested structures with Zema
---

# Objects

Validates `Map` values against a fixed set of named fields. Extra keys are silently stripped from the output by default. Validation is exhaustive: all field failures are collected before returning.

---

## Basic object

```dart
final schema = z.object({
  'name': z.string(),
  'age': z.integer(),
});

schema.parse({
  'name': 'Alice',
  'age': 30,
});  // {'name': 'Alice', 'age': 30}

schema.parse({
  'name': 'Alice',
  'age': 'thirty',  // throws ZemaException: invalid_type
});
```

---

## Nested objects

```dart
final schema = z.object({
  'user': z.object({
    'name': z.string(),
    'email': z.string().email(),
  }),
  'metadata': z.object({
    'createdAt': z.dateTime(),
    'version': z.integer(),
  }),
});

schema.parse({
  'user': {
    'name': 'Alice',
    'email': 'alice@example.com',
  },
  'metadata': {
    'createdAt': '2024-01-15T10:30:00Z',
    'version': 1,
  },
});
```

---

## Required vs optional fields

By default, all fields are required. A missing key arrives as `null`, which fails any non-optional schema.

```dart
final schema = z.object({
  'name': z.string(),
  'email': z.string(),
});

schema.parse({'name': 'Alice'});  // throws ZemaException: 'email' invalid_type
```

### Optional fields

```dart
final schema = z.object({
  'name': z.string(),
  'email': z.string(),
  'phone': z.string().optional(),
});

schema.parse({
  'name': 'Alice',
  'email': 'alice@example.com',
  // phone absent, OK, output contains phone: null
});
```

### Nullable fields

```dart
final schema = z.object({
  'name': z.string(),
  'bio': z.string().nullable(),
});

schema.parse({
  'name': 'Alice',
  'bio': null,  // valid, explicit null accepted
});
```

### Default values

```dart
final schema = z.object({
  'name': z.string(),
  'role': z.string().withDefault('user'),
  'active': z.boolean().withDefault(true),
});

schema.parse({'name': 'Alice'});
// {'name': 'Alice', 'role': 'user', 'active': true}
```

---

## Typed output with `objectAs`

Maps the validated `Map<String, dynamic>` to a custom class:

```dart
final userSchema = z.objectAs(
  {
    'name': z.string().min(2),
    'email': z.string().email(),
  },
  (map) => User(name: map['name'], email: map['email']),
);

final user = userSchema.parse(json);  // User instance, not a Map
```

If the constructor throws, a `transform_error` issue is produced.

---

## Schema composition

### `extend(shape)`

Adds or overrides fields. Returns `Map<String, dynamic>`.

```dart
final baseSchema = z.object({
  'id': z.integer(),
  'createdAt': z.dateTime(),
});

final userSchema = baseSchema.extend({
  'name': z.string(),
  'email': z.string().email(),
});

// userSchema has: id, createdAt, name, email
```

---

### `pick(keys)`

Returns a new schema with only the listed fields.

```dart
final fullSchema = z.object({
  'id': z.integer(),
  'name': z.string(),
  'email': z.string().email(),
  'password': z.string(),
});

final publicSchema = fullSchema.pick(['id', 'name', 'email']);
// password excluded
```

---

### `omit(keys)`

Returns a new schema with the listed fields removed.

```dart
final publicSchema = fullSchema.omit(['password']);
// id, name, email kept, password excluded
```

---

## Strict mode

By default, unknown keys are silently stripped. Call `makeStrict()` to reject them.

```dart
final schema = z.object({
  'name': z.string(),
}).makeStrict();

schema.parse({'name': 'Alice'});                    // OK
schema.parse({'name': 'Alice', 'extra': 'value'});  // throws ZemaException: unknown_key
```

---

## Refinements

```dart
// Cross-field validation
final schema = z.object({
  'password': z.string().min(8),
  'confirmPassword': z.string(),
}).refine(
  (data) => data['password'] == data['confirmPassword'],
  message: 'Passwords must match',
);

schema.parse({
  'password': 'secret123',
  'confirmPassword': 'secret123',
});  // OK

schema.parse({
  'password': 'secret123',
  'confirmPassword': 'different',
});  // throws ZemaException
```

---

## Error paths

Field-level issues include the field name in their path:

```dart
final result = z.object({
  'name': z.string(),
  'email': z.string().email(),
}).safeParse({'name': 'Alice', 'email': 'bad'});

// ZemaIssue(code: 'invalid_email', path: ['email'], ...)
```

`issue.pathString` formats nested paths: `'address.zip'`, `'items.[0].name'`.

---

## Common patterns

### Registration form

```dart
final registrationSchema = z.object({
  'username': z.string()
    .trim()
    .min(3)
    .max(20)
    .regex(RegExp(r'^[a-zA-Z0-9_]+$'), message: 'Alphanumeric and underscores only.'),

  'email': z.string().email(),

  'password': z.string()
    .min(8)
    .regex(RegExp(r'(?=.*[0-9])'), message: 'Must contain at least one digit.'),

  'confirmPassword': z.string(),

  'agreeToTerms': z.boolean(),
}).refine(
  (data) => data['password'] == data['confirmPassword'],
  message: 'Passwords must match',
);
```

---

### API response

```dart
final userSchema = z.object({
  'id': z.integer(),
  'username': z.string(),
  'email': z.string().email(),
  'profile': z.object({
    'avatar': z.string().url().nullable(),
    'bio': z.string().max(500).optional(),
  }),
  'createdAt': z.dateTime(),
});
```

---

### Configuration object

```dart
final configSchema = z.object({
  'database': z.object({
    'host': z.string(),
    'port': z.integer().gte(1).lte(65535),
    'ssl': z.boolean().withDefault(true),
  }),
  'server': z.object({
    'port': z.integer().withDefault(8080),
    'host': z.string().withDefault('localhost'),
    'corsOrigins': z.array(z.string()).withDefault([]),
  }),
});
```

---

## Error codes

| Code               | Trigger                               |
|--------------------|---------------------------------------|
| `invalid_type`     | Input is not a `Map`.                 |
| `unknown_key`      | Extra key present in strict mode.     |
| `transform_error`  | `objectAs` constructor threw.         |

---

## API reference

| Method            | Description                                  |
|-------------------|----------------------------------------------|
| `.extend(shape)`  | Add or override fields.                      |
| `.pick(keys)`     | Keep only the listed fields.                 |
| `.omit(keys)`     | Remove the listed fields.                    |
| `.makeStrict()`   | Reject unknown keys.                         |
| `.map(fn)`        | Transform the validated map to a new type.   |
| `.optional()`     | Allow null input.                            |
| `.withDefault(v)` | Substitute null with `v`.                    |
| `.refine(fn)`     | Add a custom cross-field validation rule.    |

---

## Next steps

- [Refinements →](./refinements): custom validation logic
- [Composition →](../composition/merging-schemas): extend, pick, omit patterns
