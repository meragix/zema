---
sidebar_position: 5
description: Handle optional and nullable fields in Zema
---

# Optional & Nullable

Learn the difference between optional and nullable fields and how to use them.

---

## The Difference

### Optional

Field can be **missing** (undefined) OR present.

```dart
final schema = z.object({
  'name': z.string(),
  'bio': z.string().optional(),
});

schema.parse({
  'name': 'Alice',
  'bio': 'Hello world',
});  // ✅ bio present

schema.parse({
  'name': 'Alice',
  // bio omitted
});  // ✅ bio missing (OK because optional)

schema.parse({
  'name': 'Alice',
  'bio': null,
});  // ❌ bio is null (not allowed by default)
```

---

### Nullable

Field must be **present** but can be **null**.

```dart
final schema = z.object({
  'name': z.string(),
  'bio': z.string().nullable(),
});

schema.parse({
  'name': 'Alice',
  'bio': 'Hello world',
});  // ✅ bio present and non-null

schema.parse({
  'name': 'Alice',
  'bio': null,
});  // ✅ bio is null (OK because nullable)

schema.parse({
  'name': 'Alice',
  // bio omitted
});  // ❌ bio missing (required field)
```

---

### Optional + Nullable

Field can be **missing** OR **null** OR present.

```dart
final schema = z.object({
  'name': z.string(),
  'bio': z.string().optional().nullable(),
});

schema.parse({
  'name': 'Alice',
  'bio': 'Hello',
});  // ✅ bio present

schema.parse({
  'name': 'Alice',
  'bio': null,
});  // ✅ bio is null

schema.parse({
  'name': 'Alice',
  // bio omitted
});  // ✅ bio missing
```

---

## Summary Table

| Schema | Missing | `null` | Value |
|--------|---------|--------|-------|
| `z.string()` | ❌ | ❌ | ✅ |
| `z.string().optional()` | ✅ | ❌ | ✅ |
| `z.string().nullable()` | ❌ | ✅ | ✅ |
| `z.string().optional().nullable()` | ✅ | ✅ | ✅ |

---

## Optional Fields

### Basic Optional

```dart
final schema = z.object({
  'email': z.string().email(),
  'phone': z.string().optional(),
});

// Extension Type
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
  String? get phone => _['phone'];  // ✅ Nullable type
}
```

---

### Optional with Default

```dart
final schema = z.object({
  'name': z.string(),
  'role': z.string().optional().default('user'),
});

schema.parse({
  'name': 'Alice',
  // role omitted → uses default
});
// Result: {'name': 'Alice', 'role': 'user'}
```

---

### Optional Arrays

```dart
final schema = z.object({
  'tags': z.array(z.string()).optional(),
});

schema.parse({});  // ✅ tags omitted
schema.parse({'tags': ['a', 'b']});  // ✅ tags present
schema.parse({'tags': null});  // ❌ tags is null
```

With default:

```dart
final schema = z.object({
  'tags': z.array(z.string()).optional().default([]),
});

schema.parse({});
// Result: {'tags': []}  (default applied)
```

---

### Optional Objects

```dart
final schema = z.object({
  'address': z.object({
    'street': z.string(),
    'city': z.string(),
  }).optional(),
});

schema.parse({});  // ✅ address omitted
schema.parse({
  'address': {
    'street': '123 Main St',
    'city': 'New York',
  },
});  // ✅ address present
```

---

## Nullable Fields

### Basic Nullable

```dart
final schema = z.object({
  'name': z.string(),
  'bio': z.string().nullable(),
});

schema.parse({
  'name': 'Alice',
  'bio': null,  // ✅ Explicitly null
});
```

---

### Nullable with Fallback

```dart
final schema = z.object({
  'avatar': z.string().url().nullable(),
});

extension type User(Map<String, dynamic> _) implements ZemaObject {
  String? get avatar => _['avatar'];
  
  // Computed property with fallback
  String get avatarUrl => avatar ?? 'https://example.com/default.png';
}
```

---

## Combining Optional & Nullable

### All Combinations

```dart
final schema = z.object({
  // Required, non-null
  'id': z.integer(),
  
  // Optional (can be missing, but not null)
  'phone': z.string().optional(),
  
  // Nullable (required but can be null)
  'bio': z.string().nullable(),
  
  // Optional + Nullable (can be missing or null)
  'avatar': z.string().url().optional().nullable(),
});

// Valid examples
schema.parse({
  'id': 123,
  'phone': '123-456-7890',
  'bio': null,
  'avatar': null,
});  // ✅

schema.parse({
  'id': 123,
  // phone omitted
  'bio': 'Hello',
  // avatar omitted
});  // ✅

schema.parse({
  'id': 123,
  'phone': null,  // ❌ phone is nullable but not optional
  'bio': 'Hello',
});
```

---

## Extension Type Patterns

### Optional Field

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get name => _['name'];
  
  // ✅ Nullable type for optional field
  String? get phone => _['phone'];
  
  // ✅ With fallback
  String get phoneOrDefault => phone ?? 'No phone';
  
  // ✅ Check presence
  bool get hasPhone => _['phone'] != null;
}
```

---

### Nullable Field

```dart
extension type Post(Map<String, dynamic> _) implements ZemaObject {
  String get title => _['title'];
  
  // ✅ Nullable type for nullable field
  String? get excerpt => _['excerpt'];
  
  // ✅ Computed from nullable
  String get displayExcerpt => excerpt ?? 'No excerpt available';
}
```

---

### Optional + Nullable Field

```dart
extension type Product(Map<String, dynamic> _) implements ZemaObject {
  String get name => _['name'];
  
  // ✅ Nullable type for optional+nullable field
  double? get discount => _['discount'];
  
  // ✅ Computed final price
  double get finalPrice {
    final basePrice = _['price'] as double;
    return discount != null ? basePrice * (1 - discount!) : basePrice;
  }
}
```

---

## Default Values

### Simple Default

```dart
final schema = z.object({
  'role': z.string().default('user'),
  'active': z.boolean().default(true),
  'count': z.integer().default(0),
});

schema.parse({});
// Result: {
//   'role': 'user',
//   'active': true,
//   'count': 0,
// }
```

---

### Computed Default

```dart
final schema = z.object({
  'id': z.string().default(() => Uuid().v4()),
  'createdAt': z.string().default(() => DateTime.now().toIso8601String()),
});

schema.parse({});
// Result: {
//   'id': '550e8400-...',  (generated UUID)
//   'createdAt': '2024-02-08T...',  (current time)
// }
```

---

### Conditional Default

```dart
final schema = z.object({
  'name': z.string(),
  'displayName': z.string().optional(),
}).transform((data) {
  // If displayName missing, use name
  if (data['displayName'] == null) {
    data['displayName'] = data['name'];
  }
  return data;
});

schema.parse({'name': 'Alice'});
// Result: {
//   'name': 'Alice',
//   'displayName': 'Alice',  (defaulted to name)
// }
```

---

## Undefined vs Null

### JavaScript/TypeScript Compatibility

```dart
// Zema treats missing fields as undefined
final schema = z.object({
  'email': z.string().optional(),
});

// These are equivalent in Zema:
schema.parse({'email': undefined});  // Missing
schema.parse({});                    // Missing

// This is different:
schema.parse({'email': null});  // ❌ Null (not allowed)
```

To allow both:

```dart
final schema = z.object({
  'email': z.string().optional().nullable(),
});

schema.parse({});               // ✅ Missing
schema.parse({'email': null});  // ✅ Null
```

---

## Real-World Examples

### User Profile

```dart
final userProfileSchema = z.object({
  // Required fields
  'id': z.string().uuid(),
  'email': z.string().email(),
  'name': z.string(),
  
  // Optional fields (can be missing)
  'phone': z.string().optional(),
  'website': z.string().url().optional(),
  
  // Nullable fields (required but can be null)
  'bio': z.string().nullable(),
  'avatar': z.string().url().nullable(),
  
  // Optional + Nullable (can be missing or null)
  'company': z.string().optional().nullable(),
  
  // With defaults
  'role': z.enum(['user', 'admin']).default('user'),
  'emailVerified': z.boolean().default(false),
  'tags': z.array(z.string()).default([]),
});

extension type UserProfile(Map<String, dynamic> _) implements ZemaObject {
  String get id => _['id'];
  String get email => _['email'];
  String get name => _['name'];
  
  String? get phone => _['phone'];
  String? get website => _['website'];
  
  String? get bio => _['bio'];
  String? get avatar => _['avatar'];
  String? get company => _['company'];
  
  String get role => _['role'];
  bool get emailVerified => _['emailVerified'];
  List<String> get tags => List<String>.from(_['tags']);
  
  // Computed
  bool get hasCompletedProfile => phone != null && bio != null;
}
```

---

### API Request

```dart
final searchRequestSchema = z.object({
  // Required
  'query': z.string().min(1),
  
  // Optional with defaults
  'page': z.integer().min(1).default(1),
  'perPage': z.integer().min(1).max(100).default(20),
  'sortBy': z.enum(['relevance', 'date', 'popularity']).default('relevance'),
  
  // Optional filters
  'category': z.string().optional(),
  'tags': z.array(z.string()).optional(),
  'dateFrom': z.string().datetime().optional(),
  'dateTo': z.string().datetime().optional(),
});
```

---

### Form Data

```dart
final registrationSchema = z.object({
  // Required fields
  'username': z.string().min(3).max(20),
  'email': z.string().email(),
  'password': z.string().min(8),
  
  // Optional fields
  'referralCode': z.string().optional(),
  'newsletter': z.boolean().optional().default(false),
  
  // Optional + Nullable
  'middleName': z.string().optional().nullable(),
});
```

---

## Common Patterns

### Required Field with Fallback

```dart
// Schema requires field
final schema = z.object({
  'count': z.integer(),
});

// But provide fallback in code
extension type Data(Map<String, dynamic> _) implements ZemaObject {
  int get count => _['count'] ?? 0;  // Fallback if somehow null
}
```

**Better:** Use default in schema:

```dart
final schema = z.object({
  'count': z.integer().default(0),
});
```

---

### Optional Field that Becomes Required

```dart
final draftSchema = z.object({
  'title': z.string(),
  'content': z.string().optional(),  // Draft can have no content
});

final publishedSchema = draftSchema.extend({
  'content': z.string().min(1),  // Published must have content
});
```

---

## Migration from Non-Nullable

### Before (No Optional)

```dart
final schema = z.object({
  'name': z.string(),
  'email': z.string(),
  'phone': z.string(),  // Always required
});
```

### After (Add Optional)

```dart
final schema = z.object({
  'name': z.string(),
  'email': z.string(),
  'phone': z.string().optional(),  // Now optional
});

// Update Extension Type
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get name => _['name'];
  String get email => _['email'];
  String? get phone => _['phone'];  // ✅ Now nullable
}
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Use nullable type for optional fields
String? get bio => _['bio'];

// ✅ Provide defaults in schema
z.string().default('user')

// ✅ Use optional for truly optional fields
'phone': z.string().optional()

// ✅ Use nullable for fields that can be explicitly null
'deletedAt': z.string().datetime().nullable()
```

### ❌ DON'T

```dart
// ❌ Non-nullable type for optional field
String get bio => _['bio'] ?? '';  // Confusing

// ❌ Optional when field is always present
'id': z.integer().optional()  // ID should be required

// ❌ Nullable without reason
'email': z.string().nullable()  // Email shouldn't be null
```

---

## API Reference

| Method | Description | Example |
|--------|-------------|---------|
| `.optional()` | Field can be missing | `z.string().optional()` |
| `.nullable()` | Field can be null | `z.string().nullable()` |
| `.default(value)` | Provide default value | `z.integer().default(0)` |
| `.default(fn)` | Computed default | `z.string().default(() => Uuid().v4())` |

---

## Next Steps

- [Refinements →](./refinements) - Custom validation rules
- [Custom Types →](./custom-types) - Define your own validators
- [Transformations →](/docs/core/transformations/transforms) - Transform data
