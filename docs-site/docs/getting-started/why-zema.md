---
sidebar_position: 4
description: Understand why Zema exists and when to use it
---

# Why Zema?

Learn why Zema exists and how it compares to alternatives.

---

## The Problem

You're building a Flutter app. You fetch data from an API:

```dart
final response = await dio.get('/users/123');
final user = User.fromJson(response.data);
```

**This looks clean. What could go wrong?**

### Scenario 1: Backend Sends Wrong Type

```json
{
  "id": "123",      // ❌ String instead of int
  "email": null,    // ❌ Null instead of String
  "age": "twenty"   // ❌ String instead of int
}
```

**Result:** Your app crashes in production with:

```
type 'String' is not a subtype of type 'int'
```

---

### Scenario 2: Backend Adds New Required Field

Backend team adds a required `role` field but forgets to tell you:

```json
{
  "id": 123,
  "email": "alice@example.com",
  "role": "admin"  // ❌ New field not in your model
}
```

**Result:** Silent data loss. Your app works but ignores the new field.

---

### Scenario 3: Data Corruption in Firestore

A bug writes invalid data to Firestore:

```json
{
  "userId": null,        // ❌ Should be string
  "createdAt": "invalid" // ❌ Should be Timestamp
}
```

**Result:** Crash when reading the document.

---

## The Solution: Runtime Validation

**Zema validates data BEFORE it enters your app:**

```dart
// Define schema
final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
  'age': z.integer().min(18),
});

// Validate API response
final result = userSchema.parse(response.data);

if (result.isSuccess) {
  // ✅ Safe to use
  final user = result.value;
} else {
  // ❌ Caught invalid data BEFORE crash
  print('Invalid data: ${result.errors}');
  // Log to Sentry, show error to user, etc.
}
```

---

## Why Not Just Use Freezed/json_serializable?

**Freezed and json_serializable are excellent tools**, but they don't validate at runtime.

### Freezed

```dart
@freezed
class User with _$User {
  factory User({
    required int id,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// ❌ No validation - crashes on invalid data
final user = User.fromJson(invalidData);  // 💥
```

**Freezed provides:**

- ✅ Type-safe models
- ✅ Immutability
- ✅ copyWith, ==, toString

**Freezed does NOT provide:**

- ❌ Runtime validation
- ❌ Schema documentation
- ❌ Reusable validation logic

---

### Zema + Freezed (Best of Both Worlds)

```dart
// 1. Define schema (validation + documentation)
final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
});

// 2. Keep your Freezed model
@freezed
class User with _$User {
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// 3. Validate THEN create Freezed instance
final user = userSchema.parse(apiData).mapTo(User.fromJson).value;
```

**Result:**

- ✅ Runtime validation (Zema)
- ✅ Type-safe models (Freezed)
- ✅ Immutability (Freezed)
- ✅ No rewriting (works together)

[→ Learn how to migrate](/docs/migration/from-freezed)

---

## Zema vs Alternatives

| Feature | Zema | Freezed | json_serializable | FormBuilder |
|---------|------|---------|-------------------|-------------|
| **Runtime validation** | ✅ | ❌ | ❌ | ✅ (forms only) |
| **Codegen required** | ❌ | ✅ | ✅ | ❌ |
| **API validation** | ✅ | ❌ | ❌ | ❌ |
| **Form validation** | ✅ | ❌ | ❌ | ✅ |
| **Storage validation** | ✅ | ❌ | ❌ | ❌ |
| **Schema reusability** | ✅ | ❌ | ❌ | 🟡 |
| **Type safety** | ✅ | ✅ | ✅ | 🟡 |
| **Hot reload speed** | ⚡ Instant | 🐌 Slow (build_runner) | 🐌 Slow | ⚡ Instant |

---

## When to Use Zema

### ✅ Use Zema When:

- You consume **external APIs** (can't trust the data)
- You use **Firestore** (data can be corrupted)
- You need **form validation** with complex rules
- You want **schema documentation** as code
- You need validation across **multiple layers** (API, storage, forms)

### ❌ Don't Use Zema When:

- You have a **100% reliable backend** (rare)
- You're building **internal tools** with trusted data only
- Performance is absolutely critical (though Zema is fast)

---

## Real-World Benefits

### 1. Catch Bugs in Staging

```dart
// Backend team changed 'age' from int to string
// Without Zema: Crashes in production
// With Zema: Caught in staging

final result = userSchema.parse(apiResponse);

if (result.isFailure) {
  // Send alert to Slack
  alertBackendTeam('User schema mismatch: ${result.errors}');
}
```

---

### 2. Better Error Messages

```dart
// Without Zema
// Error: type 'Null' is not a subtype of type 'String'
// ↑ Where? Which field? 🤷

// With Zema
// Error: Field 'email' is required
// ↑ Exact field, clear message ✅
```

---

### 3. Schema as Documentation

```dart
// Your schema IS your API documentation
final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
  'role': z.enum(['admin', 'user']),
  'createdAt': z.timestamp(),
});

// Anyone reading this knows EXACTLY what the API returns
```

---

### 4. Offline-First Apps

```dart
// Validate data before storing in Hive
final validatedData = productSchema.parse(apiData);

if (validatedData.isSuccess) {
  await hive.put('products', validatedData.value);
} else {
  // Don't corrupt local storage with invalid data
  print('Skipping invalid product: ${validatedData.errors}');
}
```

---

## Philosophy

Zema follows these principles:

### 1. Schema-First

Define your data structure **once**, validate **everywhere**:

```dart
final userSchema = z.object({...});

// Use same schema for:
✅ API responses
✅ Firestore documents
✅ Form inputs
✅ Local storage
✅ State management
```

---

### 2. Non-Invasive

Zema works **with** your existing tools, not against them:

```dart
// Keep using Freezed
@freezed class User {...}

// Add Zema validation
final user = userSchema.parse(data).mapTo(User.fromJson).value;
```

---

### 3. Progressive Adoption

Start small, grow as needed:

**Phase 1:** Add validation (guard mode)

```dart
if (data.check(userSchema).isValid) {
  // proceed
}
```

**Phase 2:** Replace manual mapping

```dart
final user = userSchema.parse(data).mapTo(User.fromJson).value;
```

**Phase 3 (optional):** Use Extension Types

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {...}
```

[→ Full migration guide](/docs/migration/overview)

---

## Performance

Zema is designed for **production use** with minimal overhead.

### Benchmarks

```
Validation of 1000 user objects:
- Zema:              ~5ms
- Manual validation: ~3ms
- No validation:     ~1ms

Difference: 4ms for 1000 objects = negligible in real apps
```

### Extension Types = Zero Cost

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}

// At runtime: User IS a Map (zero allocation)
// At compile-time: Type-safe access ✅
```

[→ Learn more about performance](/docs/core/advanced/performance)

---

## What Zema is NOT

- ❌ **Not a replacement for Freezed** - Works WITH it
- ❌ **Not a form builder** - Validates forms, doesn't build UI
- ❌ **Not an ORM** - Validates data, doesn't manage databases
- ❌ **Not a networking library** - Works with Dio/http, doesn't replace them

**Zema is a validation layer** that sits between external data and your app.

---

## Next Steps

Convinced? Get started:

- [Installation →](./installation)
- [Quick Start →](./quick-start)
- [Core Concepts →](./core-concepts)

Not convinced? See comparisons:

- [vs Freezed](/docs/comparison/vs-freezed)
- [vs json_serializable](/docs/comparison/vs-json-serializable)
- [vs FormBuilder](/docs/comparison/vs-formz)
