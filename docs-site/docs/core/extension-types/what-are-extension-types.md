---
sidebar_position: 1
description: Understanding Extension Types in Dart and why Zema uses them
---

# What are Extension Types?

Extension Types are a Dart 3.0 feature that provides **zero-cost type-safe wrappers** around existing types.

---

## The Problem

Consider this typical Dart code:

```dart
// Using a Map directly
final user = {
  'id': 123,
  'email': 'alice@example.com',
  'name': 'Alice',
};

// ❌ No type safety
print(user['emial']);  // Typo! Returns null (no compile error)
print(user['id'] + 10);  // Runtime error if id is String

// ❌ No IDE autocomplete
user['???']  // IDE can't suggest valid keys
```

---

## Traditional Solution: Classes

```dart
class User {
  final int id;
  final String email;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    name: json['name'],
  );
}

// ✅ Type-safe
final user = User(id: 123, email: 'alice@example.com', name: 'Alice');
print(user.email);  // ✅ Autocomplete works
```

**But classes have overhead:**

```dart
// Memory overhead
class User {
  final int id;        // 8 bytes
  final String email;  // 8 bytes (pointer)
  final String name;   // 8 bytes (pointer)
  // + Object header: 8-16 bytes
  // Total: ~32-40 bytes per instance
}

// Plus:
- Allocation time
- Garbage collection pressure
- Cache misses
```

---

## Extension Type Solution

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  int get id => _['id'];
  String get email => _['email'];
  String get name => _['name'];
}

// ✅ Type-safe
final user = User({'id': 123, 'email': 'alice@example.com', 'name': 'Alice'});
print(user.email);  // ✅ Autocomplete works
print(user.id + 10);  // ✅ Type: int

// ✅ Zero overhead
// At runtime, User IS just a Map<String, dynamic>
// No class instance, no object header, no allocation
```

---

## How Extension Types Work

### Compile-Time Only

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}

// During compilation:
User user = ...;
print(user.email);  // Compiler: ✅ Type-safe access

// After compilation (runtime):
// User doesn't exist!
// It's just: Map<String, dynamic> user = ...;
// print(user['email']);
```

**Key insight:** Extension Types are a **compile-time illusion**. At runtime, they're completely transparent.

---

### Zero-Cost Abstraction

```dart
// Memory layout comparison

// Class (runtime)
User object:
  Object header: 8-16 bytes
  id field: 8 bytes
  email field: 8 bytes
  name field: 8 bytes
  Total: 32-40 bytes

// Extension Type (runtime)
Map<String, dynamic>:
  Map overhead: ~24 bytes
  Entries: 3 × (key + value) ≈ 48 bytes
  Total: ~72 bytes

// Wait, Map is larger? 🤔
```

**But remember:** With Zema, you're **already using Maps** for JSON data. Extension Types add **zero additional cost** on top of that.

```dart
// Without Extension Types
final map = jsonDecode(response);  // Map<String, dynamic>
print(map['email']);  // No type safety

// With Extension Types
final user = User(jsonDecode(response));  // Still Map at runtime
print(user.email);  // ✅ Type-safe, same memory
```

---

## Benefits of Extension Types

### 1. Type Safety

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  int get age => _['age'];
}

User user = ...;

// ✅ Compile-time checks
String email = user.email;  // OK
int age = user.age;         // OK

// ❌ Compile errors
String wrong = user.emial;   // Typo caught!
int bad = user.email;        // Type mismatch!
```

---

### 2. IDE Autocomplete

```dart
user.  // IDE shows:
       // - email: String
       // - age: int
       // - name: String
```

vs

```dart
map['???']  // IDE shows nothing
```

---

### 3. Refactoring Safety

```dart
// Rename email → emailAddress

// With Extension Type:
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get emailAddress => _['emailAddress'];  // Change once
}

// All usages update automatically:
user.emailAddress  // ✅ Compiler ensures correctness

// With Map:
map['email']  // ❌ Must find/replace manually (error-prone)
```

---

### 4. Performance

```dart
// Benchmark: 1 million iterations

// Class-based
for (var i = 0; i < 1000000; i++) {
  final user = User(id: i, email: '...', name: '...');
  sink.add(user.email);
}
// Time: 250ms
// Allocations: 1 million User objects

// Extension Type
for (var i = 0; i < 1000000; i++) {
  final user = User({'id': i, 'email': '...', 'name': '...'});
  sink.add(user.email);
}
// Time: 200ms
// Allocations: 1 million Maps (no additional User objects)
// Savings: ~20% faster, less GC pressure
```

---

## Extension Types vs Alternatives

### vs Classes

| Feature | Class | Extension Type |
|---------|-------|----------------|
| Type safety | ✅ | ✅ |
| Autocomplete | ✅ | ✅ |
| Memory overhead | ❌ High | ✅ Zero |
| Allocation cost | ❌ Yes | ✅ No |
| Inheritance | ✅ | ✅ (via implements) |
| Runtime type | ✅ Distinct | ❌ Wraps underlying |

---

### vs Typedefs

```dart
// Typedef
typedef UserId = int;

UserId id = 123;
int regularInt = 456;

id = regularInt;  // ✅ Allowed (no type safety)
```

```dart
// Extension Type
extension type UserId(int _) {
  int get value => _;
}

UserId id = UserId(123);
int regularInt = 456;

id = regularInt;  // ❌ Compile error (type-safe)
```

**Extension Types provide real type safety, typedefs don't.**

---

### vs Extensions

```dart
// Extension (adds methods to existing type)
extension on Map<String, dynamic> {
  String get email => this['email'];
}

final map = {'email': 'alice@example.com'};
print(map.email);  // ✅ Works

// But:
Map<String, dynamic> unknownMap = ...;
print(unknownMap.email);  // ⚠️ Works on ANY Map (unsafe)
```

```dart
// Extension Type (creates new type)
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}

final user = User({'email': 'alice@example.com'});
print(user.email);  // ✅ Works

Map<String, dynamic> randomMap = ...;
print(randomMap.email);  // ❌ Compile error (safe!)
```

**Extension Types create distinct types, Extensions don't.**

---

## Real-World Comparison

### Without Extension Types (Just Maps)

```dart
// ❌ No type safety
final user = jsonDecode(response);

print(user['email']);     // Hope it exists
print(user['emial']);     // Typo - returns null
print(user['age'] + 10);  // Hope it's int

// Pass to function
void sendEmail(Map<String, dynamic> user) {
  final email = user['email'];  // Maybe String? Maybe null? 🤷
  // ...
}
```

---

### With Extension Types

```dart
// ✅ Type-safe
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  int get age => _['age'];
}

final user = User(jsonDecode(response));

print(user.email);       // ✅ String (guaranteed)
print(user.emial);       // ❌ Compile error
print(user.age + 10);    // ✅ int (guaranteed)

// Pass to function
void sendEmail(User user) {
  final email = user.email;  // ✅ Definitely String
  // ...
}
```

---

## Common Misconceptions

### ❌ "Extension Types are like classes"

**No.** Extension Types **disappear at runtime**.

```dart
extension type User(Map _) {...}

// Runtime
User user = ...;
print(user.runtimeType);  // Map<String, dynamic>  (NOT User!)
```

---

### ❌ "Extension Types add overhead"

**No.** Extension Types add **zero runtime cost**.

```dart
// These are identical at runtime:
Map<String, dynamic> map = {...};
User user = User({...});

// Both are just Map<String, dynamic> in memory
```

---

### ❌ "Extension Types are only for performance"

**No.** The main benefit is **type safety + developer experience**, not just performance.

```dart
// Performance is a bonus
// Real value:
✅ Autocomplete
✅ Refactoring safety
✅ Compile-time errors
✅ Self-documenting code
```

---

## When to Use Extension Types

### ✅ Use Extension Types When

- Working with external data (JSON, APIs, Firestore)
- You need type-safe access to Map data
- You want autocomplete on dynamic data
- Performance matters (high-frequency allocations)

---

### ❌ Don't Use Extension Types When

- You need distinct runtime types for pattern matching
- You need complex inheritance hierarchies
- You want runtime type checks (`is User`)
- Your data isn't already a Map

---

## Zema's Use of Extension Types

Zema uses Extension Types to wrap validated data:

```dart
// 1. Define schema
final userSchema = z.object({
  'email': z.string().email(),
  'age': z.integer(),
});

// 2. Define Extension Type
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  int get age => _['age'];
}

// 3. Validate & use
final result = userSchema.parse(apiData);

if (result.isSuccess) {
  final user = result.value as User;
  
  // ✅ Type-safe access
  print(user.email);  // String
  print(user.age);    // int
  
  // ✅ Zero overhead
  // user is just a Map at runtime
}
```

---

## Implementation Details

### The Representation Type

```dart
extension type User(Map<String, dynamic> _) {
  //                  ^^^^^^^^^^^^^^^^^^^^
  //                  Representation type
  
  String get email => _['email'];
  //                  ^
  //                  Access representation
}
```

The representation type (`Map<String, dynamic>`) is what the Extension Type wraps.

---

### The implements Clause

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  //                                       ^^^^^^^^^^
  //                                       Implements interface
}
```

`implements ZemaObject` allows Extension Types to work with Zema's validation system.

---

## Next Steps

- [Creating Extension Types →](./creating-extension-types) - How to define your own
- [Extension Types vs Classes →](./vs-classes) - Detailed comparison
- [Best Practices →](./best-practices) - Patterns and anti-patterns
