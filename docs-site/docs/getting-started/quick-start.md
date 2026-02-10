---
sidebar_position: 2
description: Build your first validated Dart app with Zema in 5 minutes
---

# Quick Start

Build a validated user profile API in 5 minutes.

---

## What We'll Build

A simple Dart app that:

1. Fetches user data from an API
2. Validates the response with Zema
3. Handles validation errors gracefully

:::tip Goal
By the end of this guide, you'll understand:

- How to define schemas
- How to validate data
- How to handle validation errors
:::

---

## Step 1: Setup Project

Create a new Dart project:

```bash
dart create -t console zema_quickstart
cd zema_quickstart
```

Add Zema to `pubspec.yaml`:

```yaml title="pubspec.yaml"
dependencies:
  zema: ^1.0.0
  http: ^1.2.0
```

Install dependencies:

```bash
dart pub get
```

---

## Step 2: Define Your Schema

Create a schema for user data.

```dart title="lib/user_schema.dart"
import 'package:zema/zema.dart';

/// Schema for user validation
final userSchema = z.object({
  'id': z.integer(),
  'name': z.string().min(2, 'Name must be at least 2 characters'),
  'email': z.string().email(),
  'age': z.integer().min(18, 'Must be 18 or older').optional(),
  'createdAt': z.string().datetime(),
});
```

**What this does:**

- `id` must be an integer
- `name` must be a string with at least 2 characters
- `email` must be a valid email format
- `age` is optional, but if provided must be ≥ 18
- `createdAt` must be an ISO 8601 datetime string

---

## Step 3: Create Extension Type

Extension Types provide type-safe access with zero runtime cost.

```dart title="lib/user.dart"
import 'package:zema/zema.dart';

extension type User(Map<String, dynamic> _) implements ZemaObject {
  int get id => _['id'];
  String get name => _['name'];
  String get email => _['email'];
  int? get age => _['age'];
  DateTime get createdAt => DateTime.parse(_['createdAt']);
}
```

:::info Why Extension Types?
Extension Types are **compile-time only** wrappers. At runtime, `User` is just a `Map<String, dynamic>`, which means:

- ✅ Zero memory allocation
- ✅ Zero performance overhead
- ✅ Type-safe access at compile-time
:::

---

## Step 4: Fetch & Validate Data

```dart title="bin/main.dart"
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zema/zema.dart';
import '../lib/user_schema.dart';
import '../lib/user.dart';

void main() async {
  // Fetch data from API
  final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/users/1'),
  );

  // Decode JSON
  final json = jsonDecode(response.body);

  // Validate with Zema
  final result = userSchema.parse(json);

  // Handle result
  if (result.isSuccess) {
    final user = result.value as User;
    
    print('✅ Valid user:');
    print('   ID: ${user.id}');
    print('   Name: ${user.name}');
    print('   Email: ${user.email}');
  } else {
    print('❌ Validation failed:');
    for (final error in result.errors) {
      final field = error.path.isEmpty ? 'root' : error.path.join('.');
      print('   $field: ${error.message}');
    }
  }
}
```

Run it:

```bash
dart run
```

**Expected output:**

```
✅ Valid user:
   ID: 1
   Name: Leanne Graham
   Email: Sincere@april.biz
```

---

## Step 5: Test with Invalid Data

Let's see what happens with invalid data.

```dart title="bin/test_invalid.dart"
import 'package:zema/zema.dart';
import '../lib/user_schema.dart';

void main() {
  // Invalid data (missing email, invalid age)
  final invalidData = {
    'id': 1,
    'name': 'A',  // ❌ Too short (min 2 chars)
    // 'email' missing ❌
    'age': 15,     // ❌ Must be ≥ 18
    'createdAt': 'not-a-date', // ❌ Invalid datetime
  };

  final result = userSchema.parse(invalidData);

  if (result.isFailure) {
    print('❌ Validation errors:');
    for (final error in result.errors) {
      final field = error.path.join('.');
      print('   • $field: ${error.message}');
    }
  }
}
```

**Output:**

```
❌ Validation errors:
   • name: Name must be at least 2 characters
   • email: Required field is missing
   • age: Must be 18 or older
   • createdAt: Invalid datetime format
```

---

## Step 6: Handle Errors Gracefully

Use pattern matching for clean error handling:

```dart
final result = userSchema.parse(json);

// Pattern matching
switch (result) {
  case ZemaSuccess(:final value):
    final user = value as User;
    print('Welcome, ${user.name}!');
    
  case ZemaFailure(:final errors):
    print('Invalid data received from server:');
    for (final error in errors) {
      print('  ${error.path.join('.')}: ${error.message}');
    }
}
```

Or use the `when` method:

```dart
result.when(
  success: (user) => print('User: ${user.name}'),
  failure: (errors) => print('Errors: ${errors.length}'),
);
```

---

## What's Next?

### Learn Core Concepts

Understand schemas, validation, and Extension Types in depth:

[→ Core Concepts](./core-concepts)

---

### Explore Plugins

Add validation to your entire stack:

<div className="row">
  <div className="col col--6">
    <a href="/docs/plugins/zema_http/overview" className="card">
      <h4>🌐 zema_http</h4>
      <p>Validate HTTP responses</p>
    </a>
  </div>
  <div className="col col--6">
    <a href="/docs/plugins/zema_form/overview" className="card">
      <h4>📝 zema_form</h4>
      <p>Form validation for Flutter</p>
    </a>
  </div>
</div>

<div className="row">
  <div className="col col--6">
    <a href="/docs/plugins/zema_hive/overview" className="card">
      <h4>💾 zema_hive</h4>
      <p>Validated local storage</p>
    </a>
  </div>
  <div className="col col--6">
    <a href="/docs/plugins/zema_firestore/overview" className="card">
      <h4>🔥 zema_firestore</h4>
      <p>Firestore validation</p>
    </a>
  </div>
</div>

---

### Real-World Examples

See complete apps using Zema:

- [TODO App](/examples/todo-app) - Form validation + local storage
- [E-commerce](/examples/e-commerce) - API validation + Firestore
- [Settings Manager](/examples/settings-app) - Reactive settings

---

## Full Code

<details>

<summary>View complete code</summary>
```dart title="lib/user_schema.dart"
import 'package:zema/zema.dart';

final userSchema = z.object({
  'id': z.integer(),
  'name': z.string().min(2),
  'email': z.string().email(),
  'age': z.integer().min(18).optional(),
  'createdAt': z.string().datetime(),
});

```

```dart title="lib/user.dart"
import 'package:zema/zema.dart';

extension type User(Map<String, dynamic> _) implements ZemaObject {
  int get id => _['id'];
  String get name => _['name'];
  String get email => _['email'];
  int? get age => _['age'];
  DateTime get createdAt => DateTime.parse(_['createdAt']);
}
```

```dart title="bin/main.dart"
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zema/zema.dart';
import '../lib/user_schema.dart';
import '../lib/user.dart';

void main() async {
  final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/users/1'),
  );

  final json = jsonDecode(response.body);
  final result = userSchema.parse(json);

  switch (result) {
    case ZemaSuccess(:final value):
      final user = value as User;
      print('✅ User: ${user.name} (${user.email})');
      
    case ZemaFailure(:final errors):
      print('❌ Validation failed:');
      for (final error in errors) {
        print('   ${error.path.join('.')}: ${error.message}');
      }
  }
}
```

</details>

---

## Next Steps

- [Core Concepts →](./core-concepts) - Deep dive into schemas
- [HTTP Plugin →](/docs/plugins/zema_http/overview) - Validate APIs
- [Migration Guide →](/docs/migration/overview) - Add Zema to existing apps
