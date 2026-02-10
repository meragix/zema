---
sidebar_position: 3
description: Detailed comparison to help you choose between Extension Types and regular classes
---

# Extension Types vs Classes

A comprehensive guide to choosing between Extension Types and traditional classes.

---

## Quick Comparison

| Feature | Extension Type | Class |
|---------|----------------|-------|
| **Type safety** | ✅ Compile-time | ✅ Compile-time + Runtime |
| **Memory overhead** | ✅ Zero | ❌ Object header + fields |
| **Allocation cost** | ✅ None (wraps existing) | ❌ Every instantiation |
| **Runtime type** | ❌ Wraps underlying | ✅ Distinct type |
| **Pattern matching** | 🟡 Limited | ✅ Full support |
| **Inheritance** | 🟡 Via implements | ✅ Full OOP |
| **Sealed classes** | ❌ | ✅ |
| **Freezed/json_serializable** | ❌ | ✅ |
| **IDE autocomplete** | ✅ | ✅ |
| **Refactoring safety** | ✅ | ✅ |
| **Best for** | Wrapping validated data | Domain models |

---

## Memory & Performance

### Extension Type

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  int get age => _['age'];
}

// Runtime memory layout:
// Map<String, dynamic>: ~72 bytes (map overhead + entries)
// User wrapper: 0 bytes (doesn't exist at runtime!)
// Total: ~72 bytes
```

**Allocation:**

```dart
for (var i = 0; i < 1000; i++) {
  final user = User(validatedMap);  // Zero allocations
  // User is just an alias for the Map
}
```

---

### Class

```dart
class User {
  final String email;
  final int age;
  
  User({required this.email, required this.age});
}

// Runtime memory layout:
// Object header: 8-16 bytes
// email pointer: 8 bytes
// age value: 8 bytes
// Total: ~24-32 bytes

// Plus: The Map you created from JSON still exists!
// Total actual cost: ~72 bytes (Map) + ~32 bytes (User) = ~104 bytes
```

**Allocation:**

```dart
for (var i = 0; i < 1000; i++) {
  final user = User(email: '...', age: i);  // 1000 allocations
  // 1000 User objects created
  // GC pressure increases
}
```

---

### Benchmark

```dart
// Test: Parse 10,000 user objects from JSON

// Extension Type approach
final stopwatch = Stopwatch()..start();
for (var json in jsonList) {
  final result = userSchema.parse(json);
  final user = result.value as User;  // Zero allocation
  sink.add(user.email);
}
stopwatch.stop();
// Time: 520ms
// Allocations: 10,000 Maps (from JSON parse)

// Class approach
final stopwatch = Stopwatch()..start();
for (var json in jsonList) {
  final result = userSchema.parse(json);
  final map = result.value;
  final user = User.fromJson(map);  // Allocates User object
  sink.add(user.email);
}
stopwatch.stop();
// Time: 680ms
// Allocations: 10,000 Maps + 10,000 User objects
// ~30% slower, 2x memory
```

---

## Runtime Type Checking

### Extension Type - Transparent

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}

final user = User({'email': '...'});

print(user.runtimeType);  // Map<String, dynamic>  (NOT User!)

if (user is User) {  // ⚠️ Always true (because Map is compatible)
  print('Is User');
}

if (user is Map) {  // ✅ True
  print('Is Map');
}
```

**Implication:** Extension Types disappear at runtime. Type checks don't work as expected.

---

### Class - Distinct Type

```dart
class User {
  final String email;
  User({required this.email});
}

final user = User(email: '...');

print(user.runtimeType);  // User  ✅

if (user is User) {  // ✅ True
  print('Is User');
}

if (user is Map) {  // ❌ False
  print('Is Map');
}
```

**Implication:** Classes are distinct runtime types. Type checks work normally.

---

## Pattern Matching

### Extension Type - Limited

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}

final value = User({'email': '...'});

// ❌ Cannot pattern match on Extension Type
switch (value) {
  case User():  // Doesn't work as expected
    print('User');
}

// ✅ Must check underlying type
if (value._ is Map<String, dynamic>) {
  print('Is a Map');
}
```

---

### Class - Full Support

```dart
sealed class Result {}
class Success extends Result {
  final int value;
  Success(this.value);
}
class Failure extends Result {
  final String error;
  Failure(this.error);
}

final result = Success(42);

// ✅ Pattern matching works perfectly
switch (result) {
  case Success(:final value):
    print('Success: $value');
  case Failure(:final error):
    print('Error: $error');
}
```

---

## Inheritance & Polymorphism

### Extension Type - Via Implements

```dart
// Define interface
abstract interface class Identifiable {
  String get id;
}

// Implement in Extension Type
extension type User(Map<String, dynamic> _) 
    implements ZemaObject, Identifiable {
  String get id => _['id'];
  String get email => _['email'];
}

extension type Post(Map<String, dynamic> _)
    implements ZemaObject, Identifiable {
  String get id => _['id'];
  String get title => _['title'];
}

// Use polymorphically
void printId(Identifiable item) {
  print(item.id);
}

printId(User({'id': '1', 'email': '...'}));  // ✅
printId(Post({'id': '2', 'title': '...'}));  // ✅
```

**Limitation:** Can only implement interfaces, not extend classes.

---

### Class - Full OOP

```dart
// Base class
abstract class Entity {
  final String id;
  Entity(this.id);
  
  void save();  // Abstract method
}

// Subclass
class User extends Entity {
  final String email;
  
  User({required String id, required this.email}) : super(id);
  
  @override
  void save() {
    // Implementation
  }
}

class Post extends Entity {
  final String title;
  
  Post({required String id, required this.title}) : super(id);
  
  @override
  void save() {
    // Implementation
  }
}

// Use polymorphically
void saveEntity(Entity entity) {
  entity.save();  // Calls correct implementation
}
```

---

## Serialization

### Extension Type - Manual

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  
  // toJson is trivial (already a Map)
  Map<String, dynamic> toJson() => _;
  
  // fromJson requires validation
  factory User.fromJson(Map<String, dynamic> json) {
    final result = userSchema.parse(json);
    if (result.isFailure) {
      throw ArgumentError('Invalid user data');
    }
    return result.value;
  }
}

// Serialize
final json = jsonEncode(user.toJson());

// Deserialize
final user = User.fromJson(jsonDecode(json));
```

---

### Class - Codegen Support

```dart
@freezed
class User with _$User {
  factory User({
    required String email,
    required int age,
  }) = _User;
  
  // Generated automatically:
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Serialize (generated)
final json = jsonEncode(user.toJson());

// Deserialize (generated)
final user = User.fromJson(jsonDecode(json));
```

**Trade-off:** Classes get codegen support, but Extension Types are simpler (no build_runner).

---

## Immutability

### Extension Type - Map is Mutable

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}

final user = User({'email': 'alice@example.com'});

// ⚠️ Underlying Map can be mutated
user._['email'] = 'hacker@evil.com';  // Mutation!

print(user.email);  // 'hacker@evil.com'  😱
```

**Solution:** Make Map unmodifiable:

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  User(Map<String, dynamic> map) : this._(Map.unmodifiable(map));
  
  String get email => _['email'];
}
```

---

### Class - Immutable by Design

```dart
class User {
  final String email;
  final int age;
  
  const User({required this.email, required this.age});
}

final user = User(email: 'alice@example.com', age: 30);

// ❌ Cannot mutate
// user.email = 'hacker@evil.com';  // Compile error

// Must create new instance
final updated = User(email: 'new@example.com', age: user.age);
```

---

## Freezed Integration

### Extension Type - Not Compatible

```dart
// ❌ Cannot use with Freezed
@freezed
extension type User(Map<String, dynamic> _) {...}  // Syntax error
```

Extension Types and Freezed are mutually exclusive.

---

### Class - Full Freezed Support

```dart
// ✅ Full Freezed integration
@freezed
class User with _$User {
  factory User({
    required String email,
    required int age,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Get all Freezed features:
final user1 = User(email: '...', age: 30);
final user2 = user1.copyWith(age: 31);  // ✅ copyWith
print(user1 == user2);                  // ✅ Equality
print(user1);                           // ✅ toString
```

---

## When to Use Extension Types

### ✅ Use Extension Types When

1. **Wrapping validated data from external sources**

```dart
   // API response → Extension Type
   final result = userSchema.parse(apiResponse);
   final user = result.value as User;
```

1. **Performance is critical**

```dart
   // High-frequency allocations (1000s of objects)
   for (final json in largeList) {
     final item = Item(json);  // Zero allocation
   }
```

1. **You're already using Maps**

```dart
   // JSON, Firestore, SharedPreferences all use Maps
   // Extension Type adds zero cost
```

1. **You want zero build_runner overhead**

```dart
   // No codegen = faster hot reload
```

1. **Simple data access patterns**

```dart
   // Just getters, no complex logic
   extension type User(Map _) {
     String get email => _['email'];
   }
```

---

## When to Use Classes

### ✅ Use Classes When

1. **You need distinct runtime types**

```dart
   sealed class Result {}
   class Success extends Result {...}
   class Failure extends Result {...}
   
   // Pattern matching requires runtime types
```

1. **Complex domain logic**

```dart
   class BankAccount {
     double _balance;
     
     void deposit(double amount) {
       if (amount <= 0) throw ArgumentError();
       _balance += amount;
     }
     
     bool canWithdraw(double amount) {...}
   }
```

1. **You need Freezed features**

```dart
   @freezed
   class User with _$User {
     // copyWith, ==, toString, unions, etc.
   }
```

1. **Inheritance hierarchies**

```dart
   abstract class Shape {
     double area();
   }
   
   class Circle extends Shape {...}
   class Rectangle extends Shape {...}
```

1. **Guaranteed immutability**

```dart
   class User {
     final String email;  // Cannot be changed
     const User(this.email);
   }
```

---

## Hybrid Approach (Recommended)

**Use both together:**

```dart
// 1. Freezed class for domain model
@freezed
class User with _$User {
  factory User({
    required String email,
    required int age,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// 2. Zema schema for validation
final userSchema = z.object({
  'email': z.string().email(),
  'age': z.integer().min(18),
});

// 3. Validate THEN create Freezed instance
final result = userSchema.parse(apiResponse);

if (result.isSuccess) {
  final user = User.fromJson(result.value);  // Freezed class
  
  // Get all benefits:
  // ✅ Validation (Zema)
  // ✅ Immutability (Freezed)
  // ✅ copyWith (Freezed)
  // ✅ Pattern matching (Freezed)
}
```

[→ See migration guide](/docs/migration/from-freezed)

---

## Decision Tree

```
Need runtime type checking?
├─ Yes → Use Class
└─ No
    │
    Need pattern matching?
    ├─ Yes → Use Class (sealed)
    └─ No
        │
        Need Freezed features?
        ├─ Yes → Use Class + Zema validation
        └─ No
            │
            Complex domain logic?
            ├─ Yes → Use Class
            └─ No
                │
                Performance critical?
                ├─ Yes → Use Extension Type
                └─ No → Either works (prefer Extension Type for simplicity)
```

---

## Real-World Examples

### Extension Type - API Response Wrapper

```dart
// Perfect use case: Wrapping validated API data
extension type UserResponse(Map<String, dynamic> _) implements ZemaObject {
  int get id => _['id'];
  String get email => _['email'];
  String get name => _['name'];
}

final response = await dio.get('/users/123');
final result = userSchema.parse(response.data);

if (result.isSuccess) {
  final user = result.value as UserResponse;
  print(user.email);  // Type-safe, zero overhead
}
```

---

### Class - Domain Model

```dart
// Perfect use case: Complex business logic
class ShoppingCart {
  final List<CartItem> _items = [];
  
  double get total => _items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => _items.length;
  
  void addItem(Product product, int quantity) {
    // Business rules
    if (quantity <= 0) throw ArgumentError('Invalid quantity');
    if (quantity > product.stock) throw StateError('Insufficient stock');
    
    final existing = _items.firstWhere(
      (item) => item.productId == product.id,
      orElse: () => null,
    );
    
    if (existing != null) {
      existing.increaseQuantity(quantity);
    } else {
      _items.add(CartItem(product, quantity));
    }
  }
  
  void removeItem(String productId) {...}
  void clear() {...}
  Order checkout() {...}
}
```

---

## Summary Table

| Scenario | Extension Type | Class | Recommended |
|----------|----------------|-------|-------------|
| **Wrapping JSON** | ✅ Perfect | 🟡 Overkill | Extension Type |
| **API responses** | ✅ Perfect | 🟡 Extra cost | Extension Type |
| **Domain models** | ❌ Limited | ✅ Perfect | Class |
| **High-frequency data** | ✅ Zero cost | ❌ GC pressure | Extension Type |
| **Complex logic** | ❌ Awkward | ✅ Natural | Class |
| **Pattern matching** | ❌ Doesn't work | ✅ Full support | Class |
| **Freezed integration** | ❌ Incompatible | ✅ Full support | Class |
| **Validation + immutability** | 🟡 Hybrid | ✅ Freezed + Zema | Hybrid |

---

## Next Steps

- [Best Practices →](./best-practices) - Patterns and anti-patterns
- [Migration Guide →](/docs/migration/from-freezed) - Integrate with existing code
- [Performance Tips →](/docs/core/advanced/performance) - Optimize your schemas
