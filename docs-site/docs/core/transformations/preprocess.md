---
sidebar_position: 2
description: Process data before validation
---

# Preprocess

Process and modify data **before** validation runs.

---

## Preprocess vs Transform

| Feature | Preprocess | Transform |
|---------|------------|-----------|
| **When** | Before validation | After validation |
| **Input** | Raw data (any type) | Validated data (type T) |
| **Output** | Data to validate | Transformed result |
| **Use case** | Data normalization | Type conversion |

---

## Basic Preprocess

```dart
final schema = z.string()
  .preprocess((value) {
    // Normalize to string
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value;
  })
  .min(3);

schema.parse(42);      // ✅ ZemaSuccess('42')
schema.parse('hello'); // ✅ ZemaSuccess('hello')
schema.parse(true);    // ❌ Validation fails (not converted)
```

**Preprocess signature:**

```dart
dynamic preprocess(dynamic value)
```

---

## Common Preprocessing

### Trim Whitespace

```dart
final schema = z.string()
  .preprocess((value) {
    if (value is String) return value.trim();
    return value;
  })
  .email();

schema.parse('  alice@example.com  ');
// ✅ ZemaSuccess('alice@example.com')
```

---

### Normalize Input

```dart
final booleanSchema = z.boolean()
  .preprocess((value) {
    // Convert various formats to boolean
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (['true', 'yes', '1'].contains(lower)) return true;
      if (['false', 'no', '0'].contains(lower)) return false;
    }
    if (value is int) {
      if (value == 1) return true;
      if (value == 0) return false;
    }
    return value;  // Let validation handle invalid values
  });

booleanSchema.parse('yes');   // ✅ ZemaSuccess(true)
booleanSchema.parse(1);       // ✅ ZemaSuccess(true)
booleanSchema.parse('no');    // ✅ ZemaSuccess(false)
booleanSchema.parse(0);       // ✅ ZemaSuccess(false)
```

---

### Remove Unwanted Characters

```dart
final phoneSchema = z.string()
  .preprocess((value) {
    if (value is! String) return value;
    // Remove all non-digit characters
    return value.replaceAll(RegExp(r'\D'), '');
  })
  .regex(RegExp(r'^\d{10}$'), 'Must be 10 digits');

phoneSchema.parse('(555) 123-4567');
// ✅ ZemaSuccess('5551234567')
```

---

### Default Values

```dart
final schema = z.integer()
  .preprocess((value) {
    // Use default if null or undefined
    return value ?? 0;
  });

schema.parse(null);  // ✅ ZemaSuccess(0)
schema.parse(42);    // ✅ ZemaSuccess(42)
```

---

## Object Preprocessing

### Add Missing Fields

```dart
final userSchema = z.object({
  'id': z.string(),
  'createdAt': z.string().datetime(),
})
  .preprocess((value) {
    if (value is! Map) return value;
    
    final map = Map<String, dynamic>.from(value);
    
    // Add createdAt if missing
    if (!map.containsKey('createdAt')) {
      map['createdAt'] = DateTime.now().toIso8601String();
    }
    
    return map;
  });

userSchema.parse({'id': '123'});
// ✅ ZemaSuccess({'id': '123', 'createdAt': '2024-02-08T...'})
```

---

### Rename Fields

```dart
final schema = z.object({
  'email': z.string().email(),
  'fullName': z.string(),
})
  .preprocess((value) {
    if (value is! Map) return value;
    
    final map = Map<String, dynamic>.from(value);
    
    // API uses 'name' but we expect 'fullName'
    if (map.containsKey('name') && !map.containsKey('fullName')) {
      map['fullName'] = map['name'];
      map.remove('name');
    }
    
    return map;
  });

schema.parse({
  'email': 'alice@example.com',
  'name': 'Alice Smith',  // Will be renamed to fullName
});
// ✅ ZemaSuccess({'email': 'alice@example.com', 'fullName': 'Alice Smith'})
```

---

### Flatten Nested Objects

```dart
final schema = z.object({
  'userId': z.string(),
  'userName': z.string(),
})
  .preprocess((value) {
    if (value is! Map) return value;
    
    // API returns nested structure
    // {'user': {'id': '1', 'name': 'Alice'}}
    
    if (value.containsKey('user')) {
      final user = value['user'] as Map;
      return {
        'userId': user['id'],
        'userName': user['name'],
      };
    }
    
    return value;
  });

schema.parse({
  'user': {
    'id': '123',
    'name': 'Alice',
  },
});
// ✅ ZemaSuccess({'userId': '123', 'userName': 'Alice'})
```

---

## Array Preprocessing

### Filter Empty Values

```dart
final schema = z.array(z.string())
  .preprocess((value) {
    if (value is! List) return value;
    
    // Remove null and empty strings
    return value
        .where((item) => item != null && item.toString().isNotEmpty)
        .toList();
  });

schema.parse(['apple', '', null, 'banana', '  ', 'orange']);
// ✅ ZemaSuccess(['apple', 'banana', 'orange'])
```

---

### Ensure Array

```dart
final schema = z.array(z.string())
  .preprocess((value) {
    // Wrap single values in array
    if (value is String) return [value];
    if (value is List) return value;
    return [];  // Default empty array
  });

schema.parse('hello');           // ✅ ZemaSuccess(['hello'])
schema.parse(['a', 'b']);        // ✅ ZemaSuccess(['a', 'b'])
schema.parse(null);              // ✅ ZemaSuccess([])
```

---

## Complex Preprocessing

### Parse JSON String

```dart
final schema = z.object({
  'name': z.string(),
  'age': z.integer(),
})
  .preprocess((value) {
    // If value is JSON string, parse it
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (e) {
        return value;  // Let validation handle invalid JSON
      }
    }
    return value;
  });

schema.parse('{"name": "Alice", "age": 30}');
// ✅ ZemaSuccess({'name': 'Alice', 'age': 30})

schema.parse({'name': 'Alice', 'age': 30});
// ✅ ZemaSuccess({'name': 'Alice', 'age': 30})
```

---

### Case-Insensitive Enum

```dart
final statusSchema = z.enum(['pending', 'active', 'completed'])
  .preprocess((value) {
    if (value is String) return value.toLowerCase();
    return value;
  });

statusSchema.parse('ACTIVE');    // ✅ ZemaSuccess('active')
statusSchema.parse('Pending');   // ✅ ZemaSuccess('pending')
```

---

### Normalize Date Formats

```dart
final dateSchema = z.string()
  .datetime()
  .preprocess((value) {
    if (value is! String) return value;
    
    // Convert MM/DD/YYYY to ISO 8601
    final mmddyyyy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final match = mmddyyyy.firstMatch(value);
    
    if (match != null) {
      final month = match.group(1);
      final day = match.group(2);
      final year = match.group(3);
      return '$year-$month-${day}T00:00:00Z';
    }
    
    return value;
  });

dateSchema.parse('02/08/2024');
// ✅ ZemaSuccess('2024-02-08T00:00:00Z')

dateSchema.parse('2024-02-08T10:30:00Z');
// ✅ ZemaSuccess('2024-02-08T10:30:00Z')
```

---

## Real-World Examples

### Form Input Sanitization

```dart
final formSchema = z.object({
  'username': z.string().min(3),
  'email': z.string().email(),
  'phone': z.string(),
})
  .preprocess((value) {
    if (value is! Map) return value;
    
    final sanitized = Map<String, dynamic>.from(value);
    
    // Trim all string fields
    sanitized.forEach((key, val) {
      if (val is String) {
        sanitized[key] = val.trim();
      }
    });
    
    // Remove phone formatting
    if (sanitized['phone'] is String) {
      sanitized['phone'] = sanitized['phone'].replaceAll(RegExp(r'\D'), '');
    }
    
    return sanitized;
  });

formSchema.parse({
  'username': '  alice  ',
  'email': '  alice@example.com  ',
  'phone': '(555) 123-4567',
});
// ✅ ZemaSuccess({
//   'username': 'alice',
//   'email': 'alice@example.com',
//   'phone': '5551234567',
// })
```

---

### API Response Normalization

```dart
// Different API versions return different structures
final productSchema = z.object({
  'id': z.string(),
  'name': z.string(),
  'price': z.double(),
})
  .preprocess((value) {
    if (value is! Map) return value;
    
    final normalized = Map<String, dynamic>.from(value);
    
    // API v1: 'product_id' → 'id'
    if (normalized.containsKey('product_id')) {
      normalized['id'] = normalized['product_id'];
      normalized.remove('product_id');
    }
    
    // API v1: 'price' as string → convert to number
    if (normalized['price'] is String) {
      normalized['price'] = double.parse(normalized['price']);
    }
    
    // API v2: nested 'details' → flatten
    if (normalized.containsKey('details')) {
      final details = normalized['details'] as Map;
      normalized['name'] = details['name'];
      normalized.remove('details');
    }
    
    return normalized;
  });

// API v1
productSchema.parse({
  'product_id': '123',
  'price': '19.99',
  'name': 'Widget',
});
// ✅ Works

// API v2
productSchema.parse({
  'id': '123',
  'price': 19.99,
  'details': {'name': 'Widget'},
});
// ✅ Works
```

---

### Legacy Data Migration

```dart
final userSchema = z.object({
  'id': z.string(),
  'email': z.string().email(),
  'role': z.enum(['admin', 'user']),
})
  .preprocess((value) {
    if (value is! Map) return value;
    
    final migrated = Map<String, dynamic>.from(value);
    
    // Old schema used 'isAdmin' boolean
    if (migrated.containsKey('isAdmin')) {
      migrated['role'] = migrated['isAdmin'] == true ? 'admin' : 'user';
      migrated.remove('isAdmin');
    }
    
    // Old schema used numeric ID
    if (migrated['id'] is int) {
      migrated['id'] = migrated['id'].toString();
    }
    
    return migrated;
  });

// Old format
userSchema.parse({
  'id': 123,
  'email': 'alice@example.com',
  'isAdmin': true,
});
// ✅ ZemaSuccess({'id': '123', 'email': 'alice@example.com', 'role': 'admin'})
```

---

## Preprocess with Transform

Combine preprocessing and transformation:

```dart
final schema = z.string()
  .preprocess((value) {
    // 1. Preprocess: Normalize input
    if (value is int) return value.toString();
    if (value is String) return value.trim();
    return value;
  })
  .min(3)  // 2. Validate
  .transform((value) => value.toUpperCase());  // 3. Transform

schema.parse('  hello  ');
// Flow:
// 1. Preprocess: '  hello  ' → 'hello'
// 2. Validate: 'hello'.length >= 3 ✅
// 3. Transform: 'hello' → 'HELLO'
// ✅ ZemaSuccess('HELLO')
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Use preprocess for data normalization
.preprocess((v) => v is String ? v.trim() : v)

// ✅ Handle type coercion
.preprocess((v) => v is int ? v.toString() : v)

// ✅ Add defaults
.preprocess((v) => v ?? defaultValue)

// ✅ Sanitize user input
.preprocess((v) => v is String ? v.replaceAll(RegExp(r'[^\w\s]'), '') : v)

// ✅ Return original value if can't process
.preprocess((v) {
  if (v is! String) return v;
  return processedValue;
})
```

---

### ❌ DON'T

```dart
// ❌ Don't do validation in preprocess
.preprocess((v) {
  if (v.length < 8) throw 'Too short';  // ❌ Use .min(8)
  return v;
})

// ❌ Don't do transformations in preprocess
.preprocess((v) => v.toUpperCase())  // ❌ Use .transform()

// ❌ Don't mutate original data
.preprocess((v) {
  v['newField'] = 'value';  // ❌ Mutation
  return v;
})
// Use: Map.from(v)..['newField'] = 'value'

// ❌ Don't do heavy async operations
.preprocess((v) async {  // ❌ Preprocess is sync
  await heavyOperation(v);
  return v;
})
```

---

## Performance Tips

### Avoid Expensive Operations

```dart
// ❌ Slow: Complex regex on every validation
z.string().preprocess((v) {
  return v.replaceAll(complexRegex, '');  // Expensive
});

// ✅ Better: Simple operations only
z.string().preprocess((v) {
  if (v is String) return v.trim();  // Cheap
  return v;
});
```

---

## API Reference

### preprocess

```dart
schema.preprocess(dynamic Function(dynamic value) fn)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `fn` | `dynamic Function(dynamic)` | Preprocessing function |

**Returns:** `ZemaSchema<T>` (same type)

---

## Next Steps

- [Transforms →](./transforms) - Transform after validation
- [Coercion →](./coercion) - Automatic type conversion
- [Custom Types →](/docs/core/schemas/custom-types) - Define custom schemas
