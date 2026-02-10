---
sidebar_position: 2
description: Learn how to define Extension Types for your Zema schemas
---

# Creating Extension Types

Step-by-step guide to creating Extension Types for validated data.

---

## Basic Extension Type

### Minimal Example

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}
```

**Parts:**

- `extension type User` - Declares new type
- `(Map<String, dynamic> _)` - Representation type (what it wraps)
- `implements ZemaObject` - Required for Zema integration
- `String get email => _['email']` - Type-safe accessor

---

## Step-by-Step Creation

### Step 1: Define Schema

```dart
final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
  'name': z.string(),
  'age': z.integer().optional(),
  'createdAt': z.string().datetime(),
});
```

---

### Step 2: Create Extension Type

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // Required fields
  int get id => _['id'];
  String get email => _['email'];
  String get name => _['name'];
  
  // Optional field (nullable)
  int? get age => _['age'];
  
  // Transform field
  DateTime get createdAt => DateTime.parse(_['createdAt']);
}
```

---

### Step 3: Validate & Use

```dart
final result = userSchema.parse(jsonData);

if (result.isSuccess) {
  final user = result.value as User;
  
  print(user.email);     // ✅ Type: String
  print(user.age);       // ✅ Type: int?
  print(user.createdAt); // ✅ Type: DateTime
}
```

---

## Field Accessors

### Required Fields

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // Simple accessor
  String get email => _['email'];
  
  // With assertion (runtime check)
  String get email => _['email'] as String;
  
  // With default (fallback)
  String get email => _['email'] ?? 'unknown@example.com';
}
```

**Recommendation:** Trust Zema validation, use simple accessors.

---

### Optional Fields

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // Optional field (can be null)
  String? get bio => _['bio'];
  
  // Optional with default
  String get bio => _['bio'] ?? 'No bio provided';
}
```

---

### Computed Properties

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  String get name => _['name'];
  
  // Computed from other fields
  String get displayName => '${name} <${email}>';
  
  // Computed with logic
  bool get isAdmin => _['roles']?.contains('admin') ?? false;
}
```

---

### Nested Objects

```dart
final userSchema = z.object({
  'profile': z.object({
    'avatar': z.string().url(),
    'bio': z.string(),
  }),
});

extension type User(Map<String, dynamic> _) implements ZemaObject {
  // Return nested object as Map
  Map<String, dynamic> get profile => _['profile'];
  
  // Or create nested Extension Type
  Profile get profile => Profile(_['profile']);
}

extension type Profile(Map<String, dynamic> _) implements ZemaObject {
  String get avatar => _['avatar'];
  String get bio => _['bio'];
}
```

---

### Arrays

```dart
final userSchema = z.object({
  'tags': z.array(z.string()),
  'roles': z.array(z.string()),
});

extension type User(Map<String, dynamic> _) implements ZemaObject {
  // Simple list
  List<String> get tags => List<String>.from(_['tags']);
  
  // With safety
  List<String> get roles => List<String>.from(_['roles'] ?? []);
}
```

---

## Type Transformations

### DateTime

```dart
final schema = z.object({
  'createdAt': z.string().datetime(),  // ISO 8601 string
});

extension type Post(Map<String, dynamic> _) implements ZemaObject {
  // Transform string → DateTime
  DateTime get createdAt => DateTime.parse(_['createdAt']);
}
```

---

### Enums

```dart
enum UserRole { admin, user, guest }

final schema = z.object({
  'role': z.enum(['admin', 'user', 'guest']),
});

extension type User(Map<String, dynamic> _) implements ZemaObject {
  // Transform string → enum
  UserRole get role {
    return UserRole.values.firstWhere(
      (e) => e.name == _['role'],
    );
  }
}
```

---

### Custom Types

```dart
class Money {
  final double amount;
  final String currency;
  
  Money(this.amount, this.currency);
}

final schema = z.object({
  'price': z.object({
    'amount': z.double(),
    'currency': z.string(),
  }),
});

extension type Product(Map<String, dynamic> _) implements ZemaObject {
  // Transform Map → Money
  Money get price {
    final priceMap = _['price'] as Map<String, dynamic>;
    return Money(priceMap['amount'], priceMap['currency']);
  }
}
```

---

## Factory Constructors

### Create from Validated Data

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  String get name => _['name'];
  
  // Factory for creating new users
  factory User.create({
    required String email,
    required String name,
  }) {
    final data = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'email': email,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Validate on creation
    final result = userSchema.parse(data);
    
    if (result.isFailure) {
      throw ArgumentError('Invalid user data: ${result.errors}');
    }
    
    return result.value;
  }
}

// Usage
final user = User.create(
  email: 'alice@example.com',
  name: 'Alice',
);
```

---

### Placeholder for Errors

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  // ... getters ...
  
  // Placeholder for error cases
  factory User.placeholder({String? id}) {
    return User({
      'id': id ?? 'unknown',
      'email': 'error@placeholder.com',
      'name': 'Error Loading User',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

// Usage with error handling
final result = userSchema.parse(apiData);

final user = result.when(
  success: (value) => value as User,
  failure: (_) => User.placeholder(),
);
```

---

## Methods

Extension Types can have methods:

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  String get name => _['name'];
  
  // Method
  String greet() => 'Hello, $name!';
  
  // Method with parameters
  bool hasRole(String role) {
    final roles = _['roles'] as List?;
    return roles?.contains(role) ?? false;
  }
  
  // Update methods (return new instance)
  User withName(String newName) {
    return User({..._,  'name': newName});
  }
}

// Usage
final user = User(...);
print(user.greet());           // "Hello, Alice!"
print(user.hasRole('admin'));  // true/false

final updated = user.withName('Bob');
```

---

## Accessing Underlying Map

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  
  // Access raw Map
  Map<String, dynamic> toJson() => _;
  
  // Copy Map
  Map<String, dynamic> copyData() => Map.from(_);
}

// Usage
final user = User(...);

final json = user.toJson();         // Same Map (reference)
final copy = user.copyData();       // New Map (copy)

// Serialize to JSON
final jsonString = jsonEncode(user.toJson());
```

---

## Implementing Operators

### Equality

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  int get id => _['id'];
  String get email => _['email'];
  
  @override
  bool operator ==(Object other) {
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

// Usage
final user1 = User({'id': 1, 'email': '...'});
final user2 = User({'id': 1, 'email': '...'});

print(user1 == user2);  // true (same id)
```

---

### Comparison

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject, Comparable<User> {
  String get name => _['name'];
  
  @override
  int compareTo(User other) {
    return name.compareTo(other.name);
  }
}

// Usage
final users = [user3, user1, user2];
users.sort();  // Sort by name
```

---

## Multiple Extension Types per Schema

You can create multiple Extension Types for the same data:

```dart
// Full user view
extension type User(Map<String, dynamic> _) implements ZemaObject {
  int get id => _['id'];
  String get email => _['email'];
  String get password => _['password'];
}

// Public user view (no password)
extension type PublicUser(Map<String, dynamic> _) implements ZemaObject {
  int get id => _['id'];
  String get email => _['email'];
  // No password accessor
}

// Usage
final user = User(data);
final publicView = PublicUser(data._);  // Same underlying Map
```

---

## Real-World Examples

### Blog Post

```dart
final postSchema = z.object({
  'id': z.string().uuid(),
  'title': z.string(),
  'content': z.string(),
  'authorId': z.string().uuid(),
  'tags': z.array(z.string()),
  'published': z.boolean(),
  'publishedAt': z.string().datetime().nullable(),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});

extension type Post(Map<String, dynamic> _) implements ZemaObject {
  String get id => _['id'];
  String get title => _['title'];
  String get content => _['content'];
  String get authorId => _['authorId'];
  List<String> get tags => List<String>.from(_['tags']);
  bool get published => _['published'];
  
  DateTime? get publishedAt {
    final dateStr = _['publishedAt'];
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }
  
  DateTime get createdAt => DateTime.parse(_['createdAt']);
  DateTime get updatedAt => DateTime.parse(_['updatedAt']);
  
  // Computed
  String get excerpt => content.length > 200
      ? '${content.substring(0, 200)}...'
      : content;
  
  bool get isDraft => !published;
  
  // Methods
  Post publish() {
    return Post({
      ..._,
      'published': true,
      'publishedAt': DateTime.now().toIso8601String(),
    });
  }
  
  Post addTag(String tag) {
    final newTags = [...tags, tag];
    return Post({..._, 'tags': newTags});
  }
}
```

---

### E-commerce Product

```dart
extension type Product(Map<String, dynamic> _) implements ZemaObject {
  String get id => _['id'];
  String get name => _['name'];
  double get price => _['price'];
  String get currency => _['currency'];
  int get stock => _['stock'];
  
  // Computed
  bool get inStock => stock > 0;
  bool get lowStock => stock > 0 && stock < 10;
  
  String get formattedPrice {
    final symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£'};
    final symbol = symbols[currency] ?? currency;
    return '$symbol${price.toStringAsFixed(2)}';
  }
  
  // Methods
  Product reduceStock(int quantity) {
    if (quantity > stock) {
      throw StateError('Insufficient stock');
    }
    
    return Product({
      ..._,
      'stock': stock - quantity,
    });
  }
}
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Keep getters simple
String get email => _['email'];

// ✅ Use nullable for optional fields
String? get bio => _['bio'];

// ✅ Transform complex types
DateTime get createdAt => DateTime.parse(_['createdAt']);

// ✅ Add computed properties
String get displayName => '${firstName} ${lastName}';

// ✅ Add helper methods
bool hasPermission(String perm) => permissions.contains(perm);
```

---

### ❌ DON'T

```dart
// ❌ Don't add validation in getters (use schema)
String get email {
  final e = _['email'];
  if (!e.contains('@')) throw 'Invalid email';
  return e;
}

// ❌ Don't mutate underlying Map
void setEmail(String email) {
  _['email'] = email;  // Mutates!
}

// ❌ Don't do heavy computation in getters
String get processedContent {
  return markdownToHtml(content);  // Expensive!
}
```

**Instead:**

- Validation → Zema schema
- Mutation → Return new instance
- Heavy computation → Separate method

---

## Next Steps

- [Extension Types vs Classes →](./vs-classes) - When to use which
- [Best Practices →](./best-practices) - Patterns and anti-patterns
- [Real-World Examples →](/docs/recipes/real-world-apps/) - Complete apps
