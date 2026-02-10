---
sidebar_position: 1
description: Introduction to Zema's core validation engine
---

# Overview

Zema's core provides the foundational building blocks for schema-based validation in Dart.

---

## What's in Core?

The `zema` package includes everything you need to define schemas and validate data:

### 1. Schema Primitives

Basic building blocks for all data types:

```dart
z.string()      // String validation
z.integer()     // Integer validation
z.double()      // Double validation
z.boolean()     // Boolean validation
z.datetime()    // DateTime validation
```

[→ Learn more about primitives](/docs/core/schemas/primitives)

---

### 2. Complex Types

Combine primitives into complex structures:

```dart
z.array(z.string())              // List<String>
z.object({'name': z.string()})   // Map<String, dynamic>
z.enum(['red', 'green', 'blue']) // Enum values
z.union([z.string(), z.integer()]) // String OR int
```

[→ Arrays](/docs/core/schemas/arrays) | [→ Objects](/docs/core/schemas/objects) | [→ Enums](/docs/core/schemas/enums)

---

### 3. Validation Methods

Two ways to validate data:

```dart
// parse() - Always returns ZemaResult
final result = schema.parse(data);

// safeParse() - Alias for parse()
final result = schema.safeParse(data);
```

[→ Learn more about validation](/docs/core/validation/basic-validation)

---

### 4. Extension Types

Zero-cost type-safe wrappers:

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}
```

[→ Learn more about Extension Types](/docs/core/extension-types/what-are-extension-types)

---

## Core Philosophy

### Schema-First

Define your data structure once, use everywhere:

```dart
// Define once
final userSchema = z.object({
  'email': z.string().email(),
  'age': z.integer().min(18),
});

// Use everywhere
✅ API validation (zema_http)
✅ Form validation (zema_form)
✅ Storage validation (zema_hive)
```

---

### Composable

Build complex schemas from simple ones:

```dart
// Simple schemas
final emailSchema = z.string().email();
final passwordSchema = z.string().min(8);

// Compose into object
final loginSchema = z.object({
  'email': emailSchema,
  'password': passwordSchema,
});

// Extend for registration
final registerSchema = loginSchema.extend({
  'confirmPassword': z.string(),
  'agreeToTerms': z.boolean(),
});
```

---

### Type-Safe

Leverage Dart's type system:

```dart
final schema = z.object({
  'count': z.integer(),
});

final result = schema.parse(data);

if (result.isSuccess) {
  final count = result.value['count'];  // ✅ Type: int
}
```

---

## Quick Reference

### Common Schemas

| Type | Schema | Example |
|------|--------|---------|
| String | `z.string()` | `'hello'` |
| Integer | `z.integer()` | `42` |
| Double | `z.double()` | `3.14` |
| Boolean | `z.boolean()` | `true` |
| DateTime | `z.datetime()` | `DateTime.now()` |
| Array | `z.array(z.string())` | `['a', 'b']` |
| Object | `z.object({'key': z.string()})` | `{'key': 'value'}` |
| Enum | `z.enum(['a', 'b'])` | `'a'` |
| Optional | `z.string().optional()` | `'hello'` or `null` |
| Nullable | `z.string().nullable()` | `'hello'` or `null` |

---

### Common Modifiers

| Modifier | Description | Example |
|----------|-------------|---------|
| `.min(n)` | Minimum value/length | `z.string().min(5)` |
| `.max(n)` | Maximum value/length | `z.integer().max(100)` |
| `.email()` | Valid email format | `z.string().email()` |
| `.url()` | Valid URL format | `z.string().url()` |
| `.regex(r)` | Matches regex | `z.string().regex(r'^[A-Z]')` |
| `.optional()` | Can be null/undefined | `z.string().optional()` |
| `.nullable()` | Can be null | `z.string().nullable()` |
| `.default(v)` | Default value | `z.integer().default(0)` |

---

### Validation Result

```dart
sealed class ZemaResult<T> {
  // Success case
  ZemaSuccess(T value)
  
  // Failure case
  ZemaFailure(List<ZemaIssue> errors)
}

// Usage
final result = schema.parse(data);

switch (result) {
  case ZemaSuccess(:final value):
    print('Valid: $value');
  case ZemaFailure(:final errors):
    print('Invalid: $errors');
}
```

---

## Learning Path

### Beginner

1. [Primitives](/docs/core/schemas/primitives) - Start here
2. [Objects](/docs/core/schemas/objects) - Nested structures
3. [Basic Validation](/docs/core/validation/basic-validation) - parse() and safeParse()

### Intermediate

1. [Arrays](/docs/core/schemas/arrays) - Lists and arrays
2. [Error Handling](/docs/core/validation/error-handling) - ZemaResult and ZemaIssue
3. [Extension Types](/docs/core/extension-types/creating-extension-types) - Zero-cost wrappers

### Advanced

1. [Refinements](/docs/core/schemas/refinements) - Custom validation
2. [Transformations](/docs/core/transformations/transforms) - Transform data
3. [Composition](/docs/core/composition/merging-schemas) - Merge and extend schemas

---

## Next Steps

Start with the fundamentals:

<div className="row">
  <div className="col col--6">
    <a href="./schemas/primitives" className="card">
      <h3>📝 Primitives</h3>
      <p>String, integer, boolean basics</p>
    </a>
  </div>
  <div className="col col--6">
    <a href="./validation/basic-validation" className="card">
      <h3>✅ Validation</h3>
      <p>How to validate data</p>
    </a>
  </div>
</div>
