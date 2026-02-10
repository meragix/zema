---
sidebar_position: 3
description: Understand the fundamental concepts of Zema validation
---

# Core Concepts

Learn the foundational concepts that power Zema.

---

## Schema-First Philosophy

Zema follows a **schema-first** approach: define your data structure once, validate everywhere.

### Traditional Approach (No Schema)

```dart
// ❌ No validation, hope for the best
class User {
  final int id;
  final String email;
  
  User.fromJson(Map<String, dynamic> json)
    : id = json['id'],        // Crashes if not int
      email = json['email'];  // Crashes if not String
}

// Use it
final user = User.fromJson(apiResponse);  // 💥 Runtime crash
```

**Problems:**

- No validation → crashes in production
- No schema documentation → API contract is implicit
- No reusability → validation logic scattered everywhere

---

### Zema Approach (Schema-First)

```dart
// ✅ Define schema once
final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
});

// ✅ Validate anywhere
final result = userSchema.parse(apiResponse);

if (result.isSuccess) {
  // Safe to use
  final user = result.value;
} else {
  // Handle errors gracefully
  print('Invalid data: ${result.errors}');
}
```

**Benefits:**

- ✅ Runtime validation → catches errors before crashes
- ✅ Schema as documentation → API contract is explicit
- ✅ Reusable → same schema for API, storage, forms, etc.

---

## Three Core Building Blocks

Zema has three fundamental concepts:

### 1. Schemas

**Schemas** define the structure and constraints of your data.

```dart
final emailSchema = z.string().email();
final ageSchema = z.integer().min(18).max(100);
final tagsSchema = z.array(z.string());
```

Think of schemas as **blueprints** for your data.

[→ Learn more about schemas](/docs/core/schemas/primitives)

---

### 2. Validation

**Validation** is the process of checking if data matches a schema.

```dart
final schema = z.string().email();

// Validate data
final result = schema.parse('alice@example.com');

if (result.isSuccess) {
  print('Valid: ${result.value}');
} else {
  print('Invalid: ${result.errors}');
}
```

Zema provides two validation methods:

| Method | Returns | Throws on Error |
|--------|---------|-----------------|
| `parse()` | `ZemaResult<T>` | ❌ No |
| `safeParse()` | `ZemaResult<T>` | ❌ No |

Both return a `ZemaResult` that you pattern-match or inspect.

[→ Learn more about validation](/docs/core/validation/basic-validation)

---

### 3. Extension Types

**Extension Types** provide zero-cost type-safe wrappers around validated data.

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  int get id => _['id'];
  String get email => _['email'];
  String get name => _['name'];
}
```

**At compile-time:**

```dart
User user = ...;
print(user.email);  // ✅ Type-safe access
```

**At runtime:**

```dart
// User is just a Map<String, dynamic>
// Zero memory allocation, zero overhead
```

[→ Learn more about Extension Types](/docs/core/extension-types/what-are-extension-types)

---

## How Zema Works

### The Validation Flow

```
┌─────────────┐
│ Raw Data    │  (Map, JSON, API response)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Schema      │  z.object({ 'email': z.string().email() })
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Validation  │  schema.parse(data)
└──────┬──────┘
       │
       ├─── ✅ Success ───▶ ZemaSuccess(validated data)
       │
       └─── ❌ Failure ───▶ ZemaFailure([errors])
```

### Example

```dart
// 1. Raw data from API
final apiResponse = {
  'email': 'not-an-email',  // ❌ Invalid
  'age': 'twenty',          // ❌ Invalid
};

// 2. Schema definition
final schema = z.object({
  'email': z.string().email(),
  'age': z.integer().min(18),
});

// 3. Validation
final result = schema.parse(apiResponse);

// 4. Result handling
switch (result) {
  case ZemaSuccess(:final value):
    print('Valid: $value');
    
  case ZemaFailure(:final errors):
    // Detailed error messages
    for (final error in errors) {
      print('${error.path.join('.')}: ${error.message}');
    }
    // Output:
    // email: Invalid email format
    // age: Expected integer, got String
}
```

---

## ZemaResult: Success or Failure

Every validation returns a `ZemaResult<T>`, which can be:

### Success

```dart
final result = z.string().parse('hello');

// result is ZemaSuccess
result.isSuccess  // true
result.value      // 'hello'
result.errors     // []
```

### Failure

```dart
final result = z.integer().parse('not-a-number');

// result is ZemaFailure
result.isFailure  // true
result.errors     // [ZemaIssue(...)]
```

### Pattern Matching

```dart
final result = schema.parse(data);

// Option 1: Switch
switch (result) {
  case ZemaSuccess(:final value):
    print('Valid: $value');
  case ZemaFailure(:final errors):
    print('Errors: $errors');
}

// Option 2: When method
result.when(
  success: (value) => print('Valid: $value'),
  failure: (errors) => print('Errors: $errors'),
);

// Option 3: If/else
if (result.isSuccess) {
  print('Valid: ${result.value}');
} else {
  print('Errors: ${result.errors}');
}
```

[→ Learn more about error handling](/docs/core/validation/error-handling)

---

## Composability

Schemas are **composable** - you build complex schemas from simple ones.

### Example: Build User Schema Step-by-Step

```dart
// 1. Start with primitives
final emailSchema = z.string().email();
final ageSchema = z.integer().min(18);

// 2. Compose into object
final userSchema = z.object({
  'email': emailSchema,
  'age': ageSchema,
  'name': z.string().min(2),
});

// 3. Add optional fields
final fullUserSchema = userSchema.extend({
  'avatar': z.string().url().optional(),
  'bio': z.string().max(500).optional(),
});

// 4. Create variants
final adminSchema = fullUserSchema.extend({
  'role': z.enum(['admin', 'superadmin']),
  'permissions': z.array(z.string()),
});
```

This is **much more maintainable** than repeating validation logic everywhere.

---

## Validation vs Transformation

Zema can both **validate** and **transform** data.

### Validation Only

```dart
final schema = z.integer().min(0).max(100);

schema.parse(50);   // ✅ ZemaSuccess(50)
schema.parse(150);  // ❌ ZemaFailure (too large)
```

### Validation + Transformation

```dart
final schema = z.string().transform((str) => str.toUpperCase());

schema.parse('hello');  // ✅ ZemaSuccess('HELLO')
```

**Common transformations:**

- Timestamps → DateTime
- Strings → Enums
- Nested Maps → Custom types

[→ Learn more about transformations](/docs/core/transformations/transforms)

---

## Where Zema Fits

Zema works at **data boundaries** - anywhere external data enters your app.

```
┌──────────────────────────────────────────┐
│          Your Flutter/Dart App           │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │                                    │ │
│  │     Your Business Logic            │ │
│  │     (Type-safe, validated data)    │ │
│  │                                    │ │
│  └────────────────────────────────────┘ │
│           ▲                              │
│           │ Zema validates here          │
│           │                              │
│  ┌────────┴───────────────────────────┐ │
│  │ Data Boundaries (External Data)    │ │
│  │                                    │ │
│  │  • API responses (zema_http)       │ │
│  │  • Firestore docs (zema_firestore) │ │
│  │  • User input (zema_form)          │ │
│  │  • Local storage (zema_hive)       │ │
│  │  • Settings (zema_shared_prefs)    │ │
│  └────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

**Zema's job:** Ensure only valid data enters your app.

---

## Type Safety: Compile-Time vs Runtime

Zema provides **both** compile-time and runtime safety.

### Compile-Time Safety (Extension Types)

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}

User user = ...;
print(user.email);  // ✅ IDE autocomplete works
// print(user.unknownField);  // ❌ Compile error
```

### Runtime Safety (Validation)

```dart
final result = userSchema.parse(untrustedData);

if (result.isSuccess) {
  // Data is guaranteed to match schema
  final user = result.value;
}
```

**Why both?**

- **Compile-time**: Catch bugs during development
- **Runtime**: Catch bugs from external data (APIs, users, etc.)

---

## Key Principles

### 1. Fail Fast

Zema validates **all fields** and returns **all errors** at once.

```dart
final schema = z.object({
  'email': z.string().email(),
  'age': z.integer().min(18),
  'name': z.string().min(2),
});

final result = schema.parse({
  'email': 'invalid',
  'age': 15,
  'name': 'A',
});

// Returns ALL errors, not just the first one
// errors = [
//   ZemaIssue(path: ['email'], message: 'Invalid email'),
//   ZemaIssue(path: ['age'], message: 'Must be ≥ 18'),
//   ZemaIssue(path: ['name'], message: 'Must be ≥ 2 chars'),
// ]
```

**Why?** Better UX - show all validation errors to the user at once.

---

### 2. Immutable by Default

Validation **never mutates** the original data.

```dart
final data = {'count': '42'};

final schema = z.object({
  'count': z.integer().coerce(),  // Converts string to int
});

final result = schema.parse(data);

print(data);          // {'count': '42'}  ← Original unchanged
print(result.value);  // {'count': 42}    ← New validated object
```

---

### 3. Explicit Over Implicit

Zema forces you to be explicit about your data structure.

```dart
// ❌ Implicit (no schema)
final user = apiResponse['user'];  // What fields does it have? 🤷

// ✅ Explicit (schema)
final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
  'name': z.string(),
});

// Now we KNOW exactly what fields exist
```

---

## Common Patterns

### Guard Pattern (Validation Only)

Use `check()` when you just want to validate without transforming:

```dart
final status = data.check(userSchema);

if (status.isValid) {
  // Proceed with data
  final user = UserClass.fromJson(data);
} else {
  // Log errors
  print('Invalid: ${status.errors}');
}
```

<!-- [→ Learn more](/docs/migration/overview#phase-1-add-validation) -->

---

### Transform Pattern (Validation + Mapping)

Use `mapTo()` to validate and transform to existing classes:

```dart
final user = userSchema.parse(data).mapTo((map) => User.fromJson(map));
```

<!-- [→ Learn more](/docs/migration/overview#phase-2-replace-manual-mapping) -->

---

### Extension Type Pattern (Zero-Cost)

Use Extension Types for maximum performance:

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}

final user = userSchema.parse(data).value as User;
print(user.email);  // Type-safe, zero allocation
```

[→ Learn more](/docs/core/extension-types/creating-extension-types)

---

## Next Steps

### Deep Dive into Schemas

Learn how to build complex schemas:

- [Primitives](/docs/core/schemas/primitives) - string, integer, boolean
- [Arrays](/docs/core/schemas/arrays) - Lists and arrays
- [Objects](/docs/core/schemas/objects) - Nested structures
- [Custom Types](/docs/core/schemas/custom-types) - Your own validators

---

### Explore Plugins

Apply schemas to your entire stack:

<!-- - [zema_http](/docs/plugins/zema_http/overview) - API validation -->
<!-- - [zema_form](/docs/plugins/zema_form/overview) - Form validation
- [zema_hive](/docs/plugins/zema_hive/overview) - Local storage
- [zema_firestore](/docs/plugins/zema_firestore/overview) - Firestore -->

---

<!-- ### Real Examples

See Zema in production apps:

- [Migration Guide](/docs/migration/overview) - Add to existing apps
- [Recipes](/docs/recipes/architecture/repository-pattern) - Best practices -->
<!-- - [Examples](/examples) - Complete applications -->
