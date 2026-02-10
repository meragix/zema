---
sidebar_position: 4
description: Patterns, anti-patterns, and tips for using Extension Types effectively
---

# Extension Types - Best Practices

Learn the patterns that make Extension Types shine and the pitfalls to avoid.

---

## ✅ DO: Keep Getters Simple

### Good ✅

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // Simple, direct access
  String get email => _['email'];
  int get age => _['age'];
  
  // Transform when needed
  DateTime get createdAt => DateTime.parse(_['createdAt']);
}
```

### Bad ❌

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // ❌ Validation in getter (should be in schema)
  String get email {
    final e = _['email'];
    if (!e.contains('@')) throw 'Invalid email';
    return e;
  }
  
  // ❌ Heavy computation in getter
  String get processedBio {
    return markdownToHtml(_['bio']);  // Expensive!
  }
}
```

**Why?**

- Validation belongs in Zema schema, not getters
- Expensive operations should be methods, not getters

**Fix:**

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];  // ✅ Trust validation
  String get bio => _['bio'];      // ✅ Raw data
  
  // ✅ Heavy computation as method
  String renderBio() => markdownToHtml(bio);
}
```

---

## ✅ DO: Use Nullable for Optional Fields

### Good ✅

```dart
final schema = z.object({
  'name': z.string(),
  'bio': z.string().optional(),  // Can be null/missing
  'age': z.integer().optional(),
});

extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get name => _['name'];
  
  // ✅ Nullable type for optional field
  String? get bio => _['bio'];
  int? get age => _['age'];
}
```

### Bad ❌

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // ❌ Non-nullable type for optional field
  String get bio => _['bio'] ?? '';  // Silent default
  int get age => _['age'] ?? 0;      // Confusing (0 vs missing)
}
```

**Why?**

- Nullable types make optionality explicit
- Defaults hide information (was it 0 or missing?)

---

## ✅ DO: Provide Factory Constructors

### Good ✅

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  String get name => _['name'];
  
  // ✅ Factory for creating new instances
  factory User.create({
    required String email,
    required String name,
  }) {
    final data = {
      'id': Uuid().v4(),
      'email': email,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    final result = userSchema.parse(data);
    
    if (result.isFailure) {
      throw ArgumentError('Invalid data: ${result.errors}');
    }
    
    return result.value;
  }
  
  // ✅ Placeholder for error cases
  factory User.placeholder() {
    return User({
      'id': 'error',
      'email': 'error@placeholder.com',
      'name': 'Error',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

// Usage
final user = User.create(
  email: 'alice@example.com',
  name: 'Alice',
);
```

---

## ✅ DO: Return New Instances for Updates

### Good ✅

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get name => _['name'];
  String get email => _['email'];
  
  // ✅ Returns new instance (immutable)
  User withName(String newName) {
    return User({..._, 'name': newName});
  }
  
  User withEmail(String newEmail) {
    return User({..._, 'email': newEmail});
  }
}

// Usage
final user = User(...);
final updated = user.withName('Bob');  // New instance

print(user.name);     // 'Alice' (original unchanged)
print(updated.name);  // 'Bob'
```

### Bad ❌

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get name => _['name'];
  
  // ❌ Mutates underlying Map
  void setName(String newName) {
    _['name'] = newName;  // Mutation!
  }
}

// Usage
final user = User(...);
user.setName('Bob');  // Mutates original

print(user.name);  // 'Bob' (original changed!)
```

**Why?**

- Immutability prevents bugs
- Easier to reason about state changes
- Follows functional programming principles

---

## ✅ DO: Add Computed Properties

### Good ✅

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get firstName => _['firstName'];
  String get lastName => _['lastName'];
  String get email => _['email'];
  
  // ✅ Computed from other fields
  String get fullName => '$firstName $lastName';
  
  // ✅ Computed with logic
  String get displayName => fullName.isEmpty ? email : fullName;
  
  // ✅ Boolean computed property
  bool get isAdmin => (_['roles'] as List? ?? []).contains('admin');
}
```

**Benefits:**

- Encapsulates logic
- Self-documenting
- Reduces duplication

---

## ❌ DON'T: Add Validation in Getters

### Bad ❌

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // ❌ Validation in getter
  String get email {
    final e = _['email'];
    if (!RegExp(r'^.+@.+\..+$').hasMatch(e)) {
      throw FormatException('Invalid email');
    }
    return e;
  }
  
  // ❌ Range check in getter
  int get age {
    final a = _['age'];
    if (a < 0 || a > 150) {
      throw RangeError('Invalid age');
    }
    return a;
  }
}
```

### Good ✅

```dart
// ✅ Validation in schema
final userSchema = z.object({
  'email': z.string().email(),
  'age': z.integer().min(0).max(150),
});

extension type User(Map<String, dynamic> _) implements ZemaObject {
  // ✅ Trust the schema validation
  String get email => _['email'];
  int get age => _['age'];
}
```

**Why?**

- Separation of concerns (validation vs access)
- Single source of truth (schema)
- Validation happens once (at parse time)

---

## ❌ DON'T: Mutate Underlying Map

### Bad ❌

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  
  // ❌ Mutates
  void updateEmail(String newEmail) {
    _['email'] = newEmail;
  }
  
  // ❌ Mutates
  void addRole(String role) {
    (_['roles'] as List).add(role);
  }
}
```

### Good ✅

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  List<String> get roles => List<String>.from(_['roles']);
  
  // ✅ Returns new instance
  User withEmail(String newEmail) {
    return User({..._, 'email': newEmail});
  }
  
  // ✅ Returns new instance
  User withRole(String role) {
    return User({
      ..._,
      'roles': [...roles, role],
    });
  }
}
```

---

## ✅ DO: Make Maps Unmodifiable (When Needed)

### Prevent Accidental Mutation

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // ✅ Wrap in unmodifiable Map
  User(Map<String, dynamic> data) : this._(Map.unmodifiable(data));
  
  String get email => _['email'];
}

// Usage
final user = User({'email': 'alice@example.com'});

// ❌ Cannot mutate
user._['email'] = 'hacker@evil.com';  // Throws UnsupportedError
```

**Trade-off:**

- ✅ Guarantees immutability
- ❌ Small performance cost (wrapping)

**When to use:**

- Critical data (authentication, payments)
- Public APIs
- When mutation bugs are likely

---

## ✅ DO: Use Type-Specific Lists

### Good ✅

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // ✅ Type-safe list
  List<String> get tags => List<String>.from(_['tags']);
  
  // ✅ Defensive copy + type safety
  List<int> get scores => List<int>.from(_['scores'] ?? []);
}
```

### Bad ❌

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // ❌ Untyped list
  List get tags => _['tags'];
  
  // ❌ Can be null, no type safety
  List? get scores => _['scores'];
}
```

**Why?**

- `List<String>.from()` ensures type safety
- Defensive copies prevent mutation
- Explicit types help IDEs

---

## ✅ DO: Document Complex Transformations

### Good ✅

```dart
extension type Event(Map<String, dynamic> _) implements ZemaObject {
  /// Parses ISO 8601 string to DateTime.
  /// 
  /// Schema ensures valid format via `z.string().datetime()`.
  DateTime get scheduledAt => DateTime.parse(_['scheduledAt']);
  
  /// Converts duration in seconds to Duration object.
  /// 
  /// Example: 3600 → Duration(hours: 1)
  Duration get duration => Duration(seconds: _['durationSeconds']);
}
```

**Why?**

- Future maintainers understand transformations
- Documents schema expectations
- Clarifies edge cases

---

## ✅ DO: Provide toJson() Method

### Good ✅

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  
  // ✅ Easy serialization
  Map<String, dynamic> toJson() => _;
  
  // ✅ Defensive copy if needed
  Map<String, dynamic> copyData() => Map.from(_);
}

// Usage
final json = jsonEncode(user.toJson());
```

---

## ✅ DO: Use Const Constructors When Possible

### Good ✅

```dart
extension type UserId(String _) {
  const UserId(this._);  // ✅ Const constructor
  
  String get value => _;
}

// Can use const
const adminId = UserId('admin-123');
```

**Benefits:**

- Compile-time constants
- Zero runtime allocation
- Can use in const contexts

---

## ❌ DON'T: Rely on Runtime Type Checks

### Bad ❌

```dart
void processData(dynamic data) {
  // ❌ Doesn't work as expected
  if (data is User) {
    print('Is User');  // Always true if data is Map!
  }
}
```

### Good ✅

```dart
void processData(dynamic data) {
  // ✅ Validate with schema
  final result = userSchema.safeParse(data);
  
  if (result.isSuccess) {
    final user = result.value as User;
    print('Is valid User');
  }
}
```

**Why?**

- Extension Types are transparent at runtime
- `is` checks test underlying type (Map), not Extension Type

---

## ✅ DO: Name Extension Types Clearly

### Good ✅

```dart
// ✅ Clear, specific names
extension type UserProfile(Map<String, dynamic> _) implements ZemaObject {...}
extension type BlogPost(Map<String, dynamic> _) implements ZemaObject {...}
extension type ProductReview(Map<String, dynamic> _) implements ZemaObject {...}
```

### Bad ❌

```dart
// ❌ Generic, unclear names
extension type Data(Map<String, dynamic> _) implements ZemaObject {...}
extension type Item(Map<String, dynamic> _) implements ZemaObject {...}
extension type Record(Map<String, dynamic> _) implements ZemaObject {...}
```

---

## ✅ DO: Group Related Extension Types

### Good ✅

```dart
// user_models.dart
extension type User(Map<String, dynamic> _) implements ZemaObject {...}
extension type UserProfile(Map<String, dynamic> _) implements ZemaObject {...}
extension type UserSettings(Map<String, dynamic> _) implements ZemaObject {...}

// product_models.dart
extension type Product(Map<String, dynamic> _) implements ZemaObject {...}
extension type ProductReview(Map<String, dynamic> _) implements ZemaObject {...}
extension type ProductVariant(Map<String, dynamic> _) implements ZemaObject {...}
```

**Benefits:**

- Easier to find related types
- Clear module boundaries
- Better code organization

---

## Real-World Pattern: Repository Layer

```dart
// schemas.dart
final userSchema = z.object({
  'id': z.string().uuid(),
  'email': z.string().email(),
  'name': z.string(),
  'createdAt': z.string().datetime(),
});

// models.dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get id => _['id'];
  String get email => _['email'];
  String get name => _['name'];
  DateTime get createdAt => DateTime.parse(_['createdAt']);
  
  factory User.create({
    required String email,
    required String name,
  }) {
    final data = {
      'id': Uuid().v4(),
      'email': email,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    final result = userSchema.parse(data);
    if (result.isFailure) {
      throw ArgumentError('Invalid user: ${result.errors}');
    }
    
    return result.value;
  }
  
  User withName(String newName) {
    return User({..._, 'name': newName});
  }
  
  Map<String, dynamic> toJson() => _;
}

// repository.dart
class UserRepository {
  final Dio _dio;
  
  UserRepository(this._dio);
  
  Future<User> getUser(String id) async {
    final response = await _dio.get('/users/$id');
    
    final result = userSchema.parse(response.data);
    
    switch (result) {
      case ZemaSuccess(:final value):
        return value as User;
        
      case ZemaFailure(:final errors):
        throw ApiException('Invalid user data', errors: errors);
    }
  }
  
  Future<User> createUser({
    required String email,
    required String name,
  }) async {
    final user = User.create(email: email, name: name);
    
    final response = await _dio.post('/users', data: user.toJson());
    
    return (userSchema.parse(response.data).value as User);
  }
  
  Future<User> updateUser(String id, {String? name}) async {
    final current = await getUser(id);
    final updated = name != null ? current.withName(name) : current;
    
    final response = await _dio.put('/users/$id', data: updated.toJson());
    
    return (userSchema.parse(response.data).value as User);
  }
}
```

---

## Checklist

### Before Creating Extension Type

- [ ] Is the data already a `Map<String, dynamic>`?
- [ ] Do I need runtime type checking? (If yes, consider class)
- [ ] Do I need pattern matching? (If yes, consider sealed class)
- [ ] Is performance critical? (If yes, Extension Type shines)
- [ ] Do I need Freezed features? (If yes, use class + Zema)

### When Defining Extension Type

- [ ] Implemented `ZemaObject`
- [ ] Simple getters (no validation/heavy computation)
- [ ] Nullable types for optional fields
- [ ] Computed properties for derived data
- [ ] Factory constructors for creation
- [ ] Update methods return new instances
- [ ] `toJson()` method for serialization
- [ ] Clear, descriptive name

### Code Review Checklist

- [ ] No validation in getters
- [ ] No mutation of underlying Map
- [ ] No heavy computation in getters
- [ ] Proper handling of optional fields
- [ ] Documentation for complex transformations
- [ ] Consistent naming conventions

---

## Anti-Patterns Summary

| Anti-Pattern | Why Bad | Fix |
|--------------|---------|-----|
| Validation in getters | Duplicates schema logic | Trust schema |
| Mutation | Breaks immutability | Return new instance |
| Heavy computation in getters | Performance | Use methods |
| Non-nullable optional fields | Hides information | Use nullable |
| Runtime type checks | Doesn't work | Use schema validation |
| Generic names | Unclear purpose | Use specific names |

---

## Next Steps

- [Transformations →](/docs/core/transformations/transforms) - Transform data during validation
- [Composition →](/docs/core/composition/merging-schemas) - Combine schemas
- [Performance →](/docs/core/advanced/performance) - Optimize validation
