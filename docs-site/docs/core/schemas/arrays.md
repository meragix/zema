---
sidebar_position: 2
description: Validate arrays and lists with Zema
---

# Arrays

Validate lists and arrays with type-safe schemas.

---

## Basic Array

```dart
final schema = z.array(z.string());

schema.parse(['a', 'b', 'c']);    // ✅ ZemaSuccess(['a', 'b', 'c'])
schema.parse([1, 2, 3]);          // ❌ ZemaFailure (not strings)
schema.parse('not an array');     // ❌ ZemaFailure
```

---

## Length Constraints

### Minimum Length

```dart
final schema = z.array(z.string()).min(2, 'Need at least 2 items');

schema.parse(['a', 'b']);      // ✅
schema.parse(['a']);           // ❌ Too few items
```

---

### Maximum Length

```dart
final schema = z.array(z.string()).max(5, 'Maximum 5 items');

schema.parse(['a', 'b', 'c']);           // ✅
schema.parse(['a', 'b', 'c', 'd', 'e', 'f']); // ❌ Too many
```

---

### Exact Length

```dart
final schema = z.array(z.string()).length(3);

schema.parse(['a', 'b', 'c']);  // ✅
schema.parse(['a', 'b']);       // ❌ Not exactly 3
```

---

### Non-Empty

```dart
final schema = z.array(z.string()).nonEmpty('Cannot be empty');

schema.parse(['a']);     // ✅
schema.parse([]);        // ❌ Empty array
```

---

## Nested Arrays

### Array of Arrays

```dart
final schema = z.array(z.array(z.integer()));

schema.parse([
  [1, 2, 3],
  [4, 5, 6],
]);  // ✅

schema.parse([
  [1, 2, 3],
  ['a', 'b'],  // ❌ Not integers
]);
```

---

### Array of Objects

```dart
final schema = z.array(
  z.object({
    'id': z.integer(),
    'name': z.string(),
  }),
);

schema.parse([
  {'id': 1, 'name': 'Alice'},
  {'id': 2, 'name': 'Bob'},
]);  // ✅

schema.parse([
  {'id': 1, 'name': 'Alice'},
  {'id': 'two', 'name': 'Bob'},  // ❌ Invalid id
]);
```

---

## Array Transformations

### Map Elements

```dart
final schema = z.array(z.string())
  .transform((list) => list.map((s) => s.toUpperCase()).toList());

schema.parse(['hello', 'world']);
// ✅ ZemaSuccess(['HELLO', 'WORLD'])
```

---

### Filter Elements

```dart
final schema = z.array(z.integer())
  .transform((list) => list.where((n) => n > 0).toList());

schema.parse([1, -2, 3, -4, 5]);
// ✅ ZemaSuccess([1, 3, 5])
```

---

## Array Refinements

### Custom Validation

```dart
final schema = z.array(z.integer())
  .refine(
    (list) => list.every((n) => n % 2 == 0),
    message: 'All numbers must be even',
  );

schema.parse([2, 4, 6]);    // ✅
schema.parse([2, 3, 4]);    // ❌ Contains odd number
```

---

### Unique Elements

```dart
final schema = z.array(z.string())
  .refine(
    (list) => list.length == list.toSet().length,
    message: 'Array must contain unique values',
  );

schema.parse(['a', 'b', 'c']);    // ✅
schema.parse(['a', 'b', 'a']);    // ❌ Duplicate 'a'
```

---

## Common Patterns

### Tags Array

```dart
final tagsSchema = z.array(z.string())
  .min(1, 'At least one tag required')
  .max(5, 'Maximum 5 tags')
  .transform((tags) => tags.map((t) => t.toLowerCase()).toList());

tagsSchema.parse(['Flutter', 'Dart', 'Mobile']);
// ✅ ZemaSuccess(['flutter', 'dart', 'mobile'])
```

---

### User List

```dart
final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
  'roles': z.array(z.string()).default([]),
});

final usersSchema = z.array(userSchema)
  .min(1, 'At least one user required');

usersSchema.parse([
  {
    'id': 1,
    'email': 'alice@example.com',
    'roles': ['admin'],
  },
  {
    'id': 2,
    'email': 'bob@example.com',
    // roles will be [] (default)
  },
]);  // ✅
```

---

### Pagination Response

```dart
final paginatedSchema = z.object({
  'items': z.array(z.object({
    'id': z.integer(),
    'title': z.string(),
  })),
  'total': z.integer(),
  'page': z.integer(),
  'perPage': z.integer(),
});

paginatedSchema.parse({
  'items': [
    {'id': 1, 'title': 'First'},
    {'id': 2, 'title': 'Second'},
  ],
  'total': 100,
  'page': 1,
  'perPage': 20,
});  // ✅
```

---

## Real-World Example

```dart
// API endpoint: GET /products
final productsResponseSchema = z.array(
  z.object({
    'id': z.string().uuid(),
    'name': z.string().min(1).max(200),
    'price': z.double().positive(),
    'tags': z.array(z.string()).default([]),
    'variants': z.array(
      z.object({
        'sku': z.string(),
        'price': z.double().positive(),
        'inStock': z.boolean(),
      }),
    ).min(1, 'At least one variant required'),
  }),
).min(0);  // Can be empty

// Usage
final response = await dio.get('/products');
final products = response.parseDataArray(productsResponseSchema);
```

---

## Performance Tips

### Avoid Deep Nesting

```dart
// ❌ Bad: Too deeply nested
z.array(z.array(z.array(z.array(z.string()))))

// ✅ Better: Flatten where possible
z.array(z.string())
```

---

### Use Lazy Validation for Large Arrays

```dart
// For very large arrays (1000+ items), consider sampling
final schema = z.array(z.object({...}))
  .refine(
    (list) {
      // Only validate first 100 items
      final sample = list.take(100);
      return sample.every((item) => /* custom check */);
    },
    message: 'Sample validation failed',
  );
```

---

## API Reference

| Method | Description | Example |
|--------|-------------|---------|
| `.min(n)` | Minimum length | `z.array(z.string()).min(2)` |
| `.max(n)` | Maximum length | `z.array(z.string()).max(10)` |
| `.length(n)` | Exact length | `z.array(z.string()).length(5)` |
| `.nonEmpty()` | At least 1 item | `z.array(z.string()).nonEmpty()` |
| `.optional()` | Can be null | `z.array(z.string()).optional()` |
| `.default(v)` | Default value | `z.array(z.string()).default([])` |

---

## Next Steps

- [Objects →](./objects) - Validate maps and nested structures
- [Enums →](./enums) - Validate enum values
- [Refinements →](./refinements) - Custom validation logic
