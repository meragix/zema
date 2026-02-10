---
sidebar_position: 3
description: Validate objects and nested structures with Zema
---

# Objects

Validate maps and nested data structures with type-safe schemas.

---

## Basic Object

```dart
final schema = z.object({
  'name': z.string(),
  'age': z.integer(),
});

schema.parse({
  'name': 'Alice',
  'age': 30,
});  // ✅ ZemaSuccess

schema.parse({
  'name': 'Alice',
  'age': 'thirty',  // ❌ Invalid type
});
```

---

## Nested Objects

### Simple Nesting

```dart
final schema = z.object({
  'user': z.object({
    'name': z.string(),
    'email': z.string().email(),
  }),
  'metadata': z.object({
    'createdAt': z.string().datetime(),
    'version': z.integer(),
  }),
});

schema.parse({
  'user': {
    'name': 'Alice',
    'email': 'alice@example.com',
  },
  'metadata': {
    'createdAt': '2024-01-15T10:30:00Z',
    'version': 1,
  },
});  // ✅
```

---

### Deep Nesting

```dart
final schema = z.object({
  'company': z.object({
    'name': z.string(),
    'address': z.object({
      'street': z.string(),
      'city': z.string(),
      'country': z.object({
        'code': z.string().length(2),
        'name': z.string(),
      }),
    }),
  }),
});

schema.parse({
  'company': {
    'name': 'Acme Inc',
    'address': {
      'street': '123 Main St',
      'city': 'New York',
      'country': {
        'code': 'US',
        'name': 'United States',
      },
    },
  },
});  // ✅
```

---

## Required vs Optional Fields

### All Required (Default)

```dart
final schema = z.object({
  'name': z.string(),
  'email': z.string(),
});

schema.parse({'name': 'Alice'});  // ❌ Missing 'email'
```

---

### Optional Fields

```dart
final schema = z.object({
  'name': z.string(),
  'email': z.string(),
  'phone': z.string().optional(),  // ✅ Optional field
});

schema.parse({
  'name': 'Alice',
  'email': 'alice@example.com',
  // phone omitted - OK
});  // ✅

schema.parse({
  'name': 'Alice',
  'email': 'alice@example.com',
  'phone': null,  // ✅ null is valid for optional
});
```

---

### Nullable Fields

```dart
final schema = z.object({
  'name': z.string(),
  'bio': z.string().nullable(),  // Can be null
});

schema.parse({
  'name': 'Alice',
  'bio': null,  // ✅ Explicitly null
});

schema.parse({
  'name': 'Alice',
  // bio missing  // ❌ Must be present (but can be null)
});
```

---

### Default Values

```dart
final schema = z.object({
  'name': z.string(),
  'role': z.string().default('user'),
  'active': z.boolean().default(true),
});

schema.parse({
  'name': 'Alice',
  // role and active will use defaults
});
// ✅ ZemaSuccess({
//   'name': 'Alice',
//   'role': 'user',
//   'active': true,
// })
```

---

## Schema Composition

### Extend

Add new fields to an existing schema:

```dart
final baseSchema = z.object({
  'id': z.integer(),
  'createdAt': z.string().datetime(),
});

final userSchema = baseSchema.extend({
  'name': z.string(),
  'email': z.string().email(),
});

// userSchema now has: id, createdAt, name, email
```

---

### Merge

Combine two schemas (overlapping fields from second schema win):

```dart
final schema1 = z.object({
  'name': z.string(),
  'age': z.integer(),
});

final schema2 = z.object({
  'age': z.integer().min(18),  // Overrides schema1's age
  'email': z.string().email(),
});

final merged = schema1.merge(schema2);

// merged has:
// - name: z.string()
// - age: z.integer().min(18)  (from schema2)
// - email: z.string().email()
```

---

### Pick

Select specific fields:

```dart
final fullSchema = z.object({
  'id': z.integer(),
  'name': z.string(),
  'email': z.string().email(),
  'password': z.string(),
});

final publicSchema = fullSchema.pick(['id', 'name', 'email']);

// publicSchema only has: id, name, email (no password)
```

---

### Omit

Exclude specific fields:

```dart
final fullSchema = z.object({
  'id': z.integer(),
  'name': z.string(),
  'email': z.string().email(),
  'password': z.string(),
});

final publicSchema = fullSchema.omit(['password']);

// publicSchema has: id, name, email (password omitted)
```

---

### Partial

Make all fields optional:

```dart
final schema = z.object({
  'name': z.string(),
  'email': z.string().email(),
  'age': z.integer(),
});

final partialSchema = schema.partial();

// All fields now optional
partialSchema.parse({});  // ✅ All fields can be omitted
partialSchema.parse({'name': 'Alice'});  // ✅
```

---

### Required

Make all fields required:

```dart
final schema = z.object({
  'name': z.string().optional(),
  'email': z.string().optional(),
});

final requiredSchema = schema.required();

// All fields now required
requiredSchema.parse({});  // ❌ Must have name and email
```

---

## Strict Mode

### Allow Unknown Keys (Default)

```dart
final schema = z.object({
  'name': z.string(),
});

schema.parse({
  'name': 'Alice',
  'unknown': 'field',  // ✅ Extra fields ignored by default
});
```

---

### Strict Mode (No Extra Keys)

```dart
final schema = z.object({
  'name': z.string(),
}).strict();

schema.parse({
  'name': 'Alice',
  'unknown': 'field',  // ❌ Unknown keys not allowed
});
```

---

### Strip Unknown Keys

```dart
final schema = z.object({
  'name': z.string(),
}).strip();

const result = schema.parse({
  'name': 'Alice',
  'unknown': 'field',
});

// ✅ ZemaSuccess({'name': 'Alice'})
// 'unknown' was stripped
```

---

## Object Refinements

### Cross-Field Validation

```dart
final schema = z.object({
  'password': z.string().min(8),
  'confirmPassword': z.string(),
}).refine(
  (data) => data['password'] == data['confirmPassword'],
  message: 'Passwords must match',
  path: ['confirmPassword'],  // Error goes to this field
);

schema.parse({
  'password': 'secret123',
  'confirmPassword': 'secret123',
});  // ✅

schema.parse({
  'password': 'secret123',
  'confirmPassword': 'different',
});  // ❌ Passwords don't match
```

---

### Conditional Fields

```dart
final schema = z.object({
  'role': z.enum(['user', 'admin']),
  'adminKey': z.string().optional(),
}).refine(
  (data) {
    if (data['role'] == 'admin') {
      return data['adminKey'] != null;
    }
    return true;
  },
  message: 'Admin role requires adminKey',
  path: ['adminKey'],
);

schema.parse({
  'role': 'admin',
  'adminKey': 'secret',
});  // ✅

schema.parse({
  'role': 'admin',
  // adminKey missing
});  // ❌ Admin requires key
```

---

## Common Patterns

### API Response

```dart
final userResponseSchema = z.object({
  'id': z.integer(),
  'username': z.string(),
  'email': z.string().email(),
  'profile': z.object({
    'avatar': z.string().url().nullable(),
    'bio': z.string().max(500).optional(),
    'location': z.string().optional(),
  }),
  'settings': z.object({
    'theme': z.enum(['light', 'dark', 'system']).default('system'),
    'notifications': z.boolean().default(true),
  }),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});
```

---

### Form Data

```dart
final registrationSchema = z.object({
  'username': z.string()
    .min(3, 'Minimum 3 characters')
    .max(20, 'Maximum 20 characters')
    .regex(RegExp(r'^[a-zA-Z0-9_]+$'), 'Invalid characters'),
    
  'email': z.string().email('Invalid email address'),
  
  'password': z.string()
    .min(8, 'Minimum 8 characters')
    .regex(
      RegExp(r'(?=.*[0-9])'),
      'Must contain at least one number',
    ),
    
  'confirmPassword': z.string(),
  
  'agreeToTerms': z.boolean(),
}).refine(
  (data) => data['password'] == data['confirmPassword'],
  message: 'Passwords must match',
  path: ['confirmPassword'],
).refine(
  (data) => data['agreeToTerms'] == true,
  message: 'You must agree to the terms',
  path: ['agreeToTerms'],
);
```

---

### Configuration Object

```dart
final configSchema = z.object({
  'database': z.object({
    'host': z.string(),
    'port': z.integer().min(1).max(65535),
    'username': z.string(),
    'password': z.string(),
    'database': z.string(),
    'ssl': z.boolean().default(true),
  }),
  'server': z.object({
    'port': z.integer().default(8080),
    'host': z.string().default('localhost'),
    'cors': z.object({
      'enabled': z.boolean().default(false),
      'origins': z.array(z.string()).default([]),
    }),
  }),
  'logging': z.object({
    'level': z.enum(['debug', 'info', 'warn', 'error']).default('info'),
    'file': z.string().optional(),
  }),
});
```

---

## Performance Tips

### Reuse Schemas

```dart
// ❌ Bad: Recreating schema every time
void validateUser(Map<String, dynamic> data) {
  final schema = z.object({...});  // Created every call
  schema.parse(data);
}

// ✅ Good: Define once, reuse
final userSchema = z.object({...});

void validateUser(Map<String, dynamic> data) {
  userSchema.parse(data);  // Reuses same schema
}
```

---

### Avoid Deep Nesting

```dart
// ❌ Bad: Too deeply nested
z.object({
  'a': z.object({
    'b': z.object({
      'c': z.object({
        'd': z.object({
          'e': z.string(),
        }),
      }),
    }),
  }),
});

// ✅ Better: Flatten where possible
final eSchema = z.object({'e': z.string()});
final dSchema = z.object({'d': eSchema});
// etc.
```

---

## Real-World Example

```dart
// E-commerce product schema
final productSchema = z.object({
  'id': z.string().uuid(),
  'sku': z.string().regex(RegExp(r'^[A-Z0-9-]+$')),
  'name': z.string().min(1).max(200),
  'description': z.string().max(2000),
  
  'pricing': z.object({
    'price': z.double().positive(),
    'currency': z.string().length(3),  // USD, EUR, etc.
    'discount': z.object({
      'percentage': z.double().min(0).max(1),
      'validUntil': z.string().datetime().optional(),
    }).optional(),
  }),
  
  'inventory': z.object({
    'quantity': z.integer().nonNegative(),
    'warehouse': z.string(),
    'reserved': z.integer().nonNegative().default(0),
  }),
  
  'attributes': z.object({
    'color': z.string().optional(),
    'size': z.string().optional(),
    'weight': z.double().positive().optional(),
  }),
  
  'media': z.object({
    'images': z.array(z.string().url()).min(1, 'At least one image required'),
    'videos': z.array(z.string().url()).default([]),
  }),
  
  'status': z.enum(['draft', 'active', 'archived']).default('draft'),
  'tags': z.array(z.string()).default([]),
  
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
}).refine(
  (data) {
    // Stock quantity must be >= reserved
    final inventory = data['inventory'] as Map;
    return inventory['quantity'] >= inventory['reserved'];
  },
  message: 'Available quantity cannot be less than reserved',
  path: ['inventory', 'quantity'],
);

// Usage with API
final response = await dio.get('/products/123');
final product = response.parseData(productSchema);
```

---

## API Reference

### Object Methods

| Method | Description | Example |
|--------|-------------|---------|
| `.extend(fields)` | Add new fields | `schema.extend({'age': z.integer()})` |
| `.merge(schema)` | Merge two schemas | `schema1.merge(schema2)` |
| `.pick(keys)` | Select fields | `schema.pick(['id', 'name'])` |
| `.omit(keys)` | Exclude fields | `schema.omit(['password'])` |
| `.partial()` | All fields optional | `schema.partial()` |
| `.required()` | All fields required | `schema.required()` |
| `.strict()` | No extra keys | `schema.strict()` |
| `.strip()` | Remove extra keys | `schema.strip()` |
| `.refine()` | Custom validation | `schema.refine((d) => ...)` |

---

## Next Steps

- [Enums →](./enums) - Validate enum values
- [Optional/Nullable →](./optional-nullable) - Handle missing data
- [Refinements →](./refinements) - Custom validation logic
- [Extension Types →](/docs/core/extension-types/creating-extension-types) - Type-safe wrappers
