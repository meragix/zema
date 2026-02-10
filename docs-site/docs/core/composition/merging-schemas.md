---
sidebar_position: 1
description: Combine and reuse schemas with merge and extend
---

# Merging & Extending Schemas

Learn how to compose schemas by merging and extending them.

---

## Extend

Add new fields to an existing schema:

```dart
final baseSchema = z.object({
  'id': z.integer(),
  'createdAt': z.string().datetime(),
});

final userSchema = baseSchema.extend({
  'email': z.string().email(),
  'name': z.string(),
});

// userSchema has: id, createdAt, email, name
userSchema.parse({
  'id': 123,
  'createdAt': '2024-02-08T10:30:00Z',
  'email': 'alice@example.com',
  'name': 'Alice',
});
// ✅ Valid
```

---

## Merge

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

final mergedSchema = schema1.merge(schema2);

// mergedSchema has:
// - name: z.string()  (from schema1)
// - age: z.integer().min(18)  (from schema2, overrides schema1)
// - email: z.string().email()  (from schema2)
```

---

## Extend vs Merge

| Method | Overlapping Fields | Use Case |
|--------|-------------------|----------|
| `extend` | ❌ Error if overlap | Add new fields only |
| `merge` | ✅ Second wins | Override/combine schemas |

---

## Common Patterns

### Base Entity Schema

```dart
// Base schema for all entities
final entitySchema = z.object({
  'id': z.string().uuid(),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});

// Extend for specific entities
final userSchema = entitySchema.extend({
  'email': z.string().email(),
  'name': z.string(),
  'role': z.enum(['admin', 'user']),
});

final postSchema = entitySchema.extend({
  'title': z.string(),
  'content': z.string(),
  'authorId': z.string().uuid(),
});

final commentSchema = entitySchema.extend({
  'content': z.string(),
  'postId': z.string().uuid(),
  'authorId': z.string().uuid(),
});
```

---

### Timestamps Mixin

```dart
final timestampsSchema = z.object({
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});

final productSchema = z.object({
  'id': z.string(),
  'name': z.string(),
  'price': z.double(),
}).merge(timestampsSchema);

// productSchema has: id, name, price, createdAt, updatedAt
```

---

### Audit Fields

```dart
final auditSchema = z.object({
  'createdBy': z.string().uuid(),
  'updatedBy': z.string().uuid().optional(),
  'deletedBy': z.string().uuid().optional(),
  'deletedAt': z.string().datetime().optional(),
});

final documentSchema = z.object({
  'id': z.string(),
  'title': z.string(),
  'content': z.string(),
}).merge(auditSchema);
```

---

## Versioned Schemas

```dart
// Version 1
final userV1Schema = z.object({
  'id': z.integer(),
  'name': z.string(),
});

// Version 2: Add email (optional for backward compat)
final userV2Schema = userV1Schema.extend({
  'email': z.string().email().optional(),
});

// Version 3: Make email required, add role
final userV3Schema = userV2Schema.merge(z.object({
  'email': z.string().email(),  // Override to make required
  'role': z.enum(['admin', 'user']).default('user'),
}));
```

---

## Inheritance-like Composition

```dart
// Base person
final personSchema = z.object({
  'firstName': z.string(),
  'lastName': z.string(),
  'dateOfBirth': z.string().datetime(),
});

// Employee extends Person
final employeeSchema = personSchema.extend({
  'employeeId': z.string(),
  'department': z.string(),
  'salary': z.double(),
});

// Customer extends Person
final customerSchema = personSchema.extend({
  'customerId': z.string(),
  'loyaltyPoints': z.integer().default(0),
});
```

---

## Composition with Shared Fields

```dart
// Shared address schema
final addressSchema = z.object({
  'street': z.string(),
  'city': z.string(),
  'zipCode': z.string(),
  'country': z.string(),
});

// User with address
final userSchema = z.object({
  'id': z.string(),
  'name': z.string(),
  'billingAddress': addressSchema,
  'shippingAddress': addressSchema.optional(),
});
```

---

## Override with Merge

```dart
// Base product with strict pricing
final baseProductSchema = z.object({
  'name': z.string().min(3),
  'price': z.double().positive(),
  'stock': z.integer().nonNegative(),
});

// Premium product: override price to require min $100
final premiumProductSchema = baseProductSchema.merge(z.object({
  'price': z.double().min(100),
}));

premiumProductSchema.parse({
  'name': 'Luxury Item',
  'price': 50,  // ❌ Must be >= 100
  'stock': 10,
});
```

---

## Nested Schema Composition

```dart
// Profile schema
final profileSchema = z.object({
  'avatar': z.string().url().optional(),
  'bio': z.string().max(500).optional(),
});

// Settings schema
final settingsSchema = z.object({
  'theme': z.enum(['light', 'dark']).default('light'),
  'notifications': z.boolean().default(true),
});

// User with nested schemas
final userSchema = z.object({
  'id': z.string(),
  'email': z.string().email(),
  'profile': profileSchema.optional(),
  'settings': settingsSchema.default({
    'theme': 'light',
    'notifications': true,
  }),
});
```

---

## Multiple Inheritance Simulation

```dart
// Timestampable
final timestampable = z.object({
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});

// Identifiable
final identifiable = z.object({
  'id': z.string().uuid(),
});

// Auditable
final auditable = z.object({
  'createdBy': z.string(),
  'updatedBy': z.string().optional(),
});

// Combine multiple "mixins"
final documentSchema = z.object({
  'title': z.string(),
  'content': z.string(),
})
  .merge(identifiable)
  .merge(timestampable)
  .merge(auditable);

// documentSchema has: title, content, id, createdAt, updatedAt, createdBy, updatedBy
```

---

## Conditional Extension

```dart
// Base schema
final baseSchema = z.object({
  'type': z.enum(['basic', 'premium']),
  'name': z.string(),
});

// Conditionally extend based on environment
final schema = kDebugMode
  ? baseSchema.extend({
      'debugInfo': z.object({
        'timestamp': z.string().datetime(),
        'source': z.string(),
      }),
    })
  : baseSchema;
```

---

## Real-World Example: E-commerce

```dart
// Base entity
final entitySchema = z.object({
  'id': z.string().uuid(),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});

// Priceable items
final priceableSchema = z.object({
  'price': z.double().positive(),
  'currency': z.string().length(3).default('USD'),
  'discount': z.double().min(0).max(1).optional(),
});

// Product
final productSchema = entitySchema
  .merge(priceableSchema)
  .extend({
    'name': z.string(),
    'description': z.string(),
    'sku': z.string(),
    'stock': z.integer().nonNegative(),
    'categoryId': z.string().uuid(),
  });

// Order item
final orderItemSchema = priceableSchema.extend({
  'productId': z.string().uuid(),
  'quantity': z.integer().positive(),
  'total': z.double().positive(),
});

// Order
final orderSchema = entitySchema.extend({
  'customerId': z.string().uuid(),
  'items': z.array(orderItemSchema).min(1),
  'subtotal': z.double().positive(),
  'tax': z.double().nonNegative(),
  'total': z.double().positive(),
  'status': z.enum(['pending', 'paid', 'shipped', 'delivered', 'cancelled']),
});
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Create reusable base schemas
final baseEntity = z.object({...});

// ✅ Use extend for adding fields
baseEntity.extend({'newField': z.string()});

// ✅ Use merge for overriding fields
schema1.merge(schema2);  // schema2 fields override

// ✅ Compose multiple schemas
schema
  .merge(timestamps)
  .merge(audit)
  .extend({...});
```

---

### ❌ DON'T

```dart
// ❌ Don't extend with overlapping fields
baseSchema.extend({
  'id': z.integer(),  // ❌ Error if 'id' already in baseSchema
});

// ❌ Don't deeply nest extends/merges
schema
  .extend({...})
  .extend({...})
  .extend({...})
  .extend({...});  // Hard to read

// ❌ Don't create circular dependencies
const schema1 = schema2.extend({...});
const schema2 = schema1.extend({...});  // ❌ Circular
```

---

## API Reference

### extend

```dart
schema.extend(Map<String, ZemaSchema> fields)
```

Adds new fields to schema. **Errors if fields overlap.**

---

### merge

```dart
schema1.merge(schema2)
```

Combines two schemas. **Second schema fields override first.**

---

## Next Steps

- [Picking & Omitting →](./picking-omitting) - Select specific fields
- [Discriminated Unions →](./discriminated-unions) - Type-based composition
- [Lazy Schemas →](/docs/core/advanced/lazy-schemas) - Recursive schemas
