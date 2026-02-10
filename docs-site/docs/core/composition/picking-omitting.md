---
sidebar_position: 2
description: Select or exclude specific fields from schemas
---

# Picking & Omitting Fields

Create subsets of schemas by picking or omitting specific fields.

---

## Pick

Select only specific fields from a schema:

```dart
final userSchema = z.object({
  'id': z.string(),
  'email': z.string().email(),
  'password': z.string(),
  'name': z.string(),
  'role': z.string(),
});

// Pick only safe fields for API response
final publicUserSchema = userSchema.pick(['id', 'email', 'name']);

// publicUserSchema only has: id, email, name
publicUserSchema.parse({
  'id': '123',
  'email': 'alice@example.com',
  'name': 'Alice',
  // password and role omitted
});
// ✅ Valid
```

---

## Omit

Exclude specific fields from a schema:

```dart
final userSchema = z.object({
  'id': z.string(),
  'email': z.string().email(),
  'password': z.string(),
  'name': z.string(),
  'role': z.string(),
});

// Omit sensitive fields
final publicUserSchema = userSchema.omit(['password']);

// publicUserSchema has: id, email, name, role (no password)
publicUserSchema.parse({
  'id': '123',
  'email': 'alice@example.com',
  'name': 'Alice',
  'role': 'user',
  // password omitted
});
// ✅ Valid
```

---

## Pick vs Omit

| Method | Description | When to Use |
|--------|-------------|-------------|
| `pick` | Include only listed fields | When you want a small subset |
| `omit` | Exclude listed fields | When you want most fields |

---

## Common Patterns

### Public vs Private Data

```dart
final userSchema = z.object({
  'id': z.string(),
  'email': z.string().email(),
  'password': z.string(),
  'salt': z.string(),
  'name': z.string(),
  'createdAt': z.string().datetime(),
});

// Public API response (no sensitive data)
final publicUserSchema = userSchema.omit(['password', 'salt']);

// Admin API response (everything)
final adminUserSchema = userSchema;

// Login request (only credentials)
final loginSchema = userSchema.pick(['email', 'password']);
```

---

### Form Schemas

```dart
final productSchema = z.object({
  'id': z.string().uuid(),
  'name': z.string(),
  'price': z.double(),
  'stock': z.integer(),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});

// Create form (no id or timestamps)
final createProductSchema = productSchema.omit([
  'id',
  'createdAt',
  'updatedAt',
]);

// Update form (no id or createdAt)
final updateProductSchema = productSchema.omit([
  'id',
  'createdAt',
]);

// Response (full object)
final productResponseSchema = productSchema;
```

---

### API Request/Response

```dart
final postSchema = z.object({
  'id': z.string(),
  'title': z.string(),
  'content': z.string(),
  'authorId': z.string(),
  'published': z.boolean(),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});

// POST request (create new post)
final createPostSchema = postSchema.omit([
  'id',
  'createdAt',
  'updatedAt',
]);

// PUT request (update existing post)
final updatePostSchema = postSchema.pick([
  'title',
  'content',
  'published',
]);

// GET response (full post)
final postResponseSchema = postSchema;
```

---

## Nested Picking/Omitting

### Pick from Nested Schema

```dart
final userSchema = z.object({
  'id': z.string(),
  'email': z.string(),
  'profile': z.object({
    'avatar': z.string().url(),
    'bio': z.string(),
    'website': z.string().url().optional(),
  }),
});

// Pick top-level fields
final basicUserSchema = userSchema.pick(['id', 'email']);

// For nested fields, recreate manually
final userWithBasicProfileSchema = z.object({
  'id': z.string(),
  'email': z.string(),
  'profile': z.object({
    'avatar': z.string().url(),
    // bio and website omitted
  }),
});
```

---

## Combining Pick/Omit with Extend

```dart
final baseUserSchema = z.object({
  'id': z.string(),
  'email': z.string().email(),
  'password': z.string(),
  'name': z.string(),
});

// Public schema + additional computed field
final publicUserSchema = baseUserSchema
  .omit(['password'])
  .extend({
    'displayName': z.string(),
  });

// publicUserSchema has: id, email, name, displayName
```

---

## Multiple Pick/Omit Operations

```dart
final userSchema = z.object({
  'id': z.string(),
  'email': z.string(),
  'password': z.string(),
  'name': z.string(),
  'role': z.string(),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});

// Chain operations
final schema = userSchema
  .omit(['password'])          // Remove password
  .omit(['createdAt', 'updatedAt'])  // Remove timestamps
  .pick(['id', 'email', 'name']);    // Keep only these

// Equivalent to:
final schema2 = userSchema.pick(['id', 'email', 'name']);
```

---

## Real-World Examples

### User Management API

```dart
// Full user model
final userSchema = z.object({
  'id': z.string().uuid(),
  'email': z.string().email(),
  'password': z.string(),
  'salt': z.string(),
  'firstName': z.string(),
  'lastName': z.string(),
  'role': z.enum(['admin', 'user', 'guest']),
  'emailVerified': z.boolean(),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
  'lastLogin': z.string().datetime().optional(),
});

// POST /auth/register (create user)
final registerSchema = userSchema.pick([
  'email',
  'password',
  'firstName',
  'lastName',
]);

// POST /auth/login (credentials only)
final loginSchema = userSchema.pick(['email', 'password']);

// GET /users/:id (public profile)
final publicProfileSchema = userSchema.pick([
  'id',
  'firstName',
  'lastName',
  'createdAt',
]);

// GET /users/me (current user)
final currentUserSchema = userSchema.omit([
  'password',
  'salt',
]);

// PATCH /users/:id (update profile)
final updateProfileSchema = userSchema.pick([
  'firstName',
  'lastName',
]);

// Admin endpoint GET /admin/users/:id
final adminUserSchema = userSchema.omit(['password', 'salt']);
```

---

### E-commerce Product

```dart
final productSchema = z.object({
  'id': z.string().uuid(),
  'sku': z.string(),
  'name': z.string(),
  'description': z.string(),
  'price': z.double(),
  'compareAtPrice': z.double().optional(),
  'costPrice': z.double(),
  'stock': z.integer(),
  'lowStockThreshold': z.integer(),
  'categoryId': z.string().uuid(),
  'vendorId': z.string().uuid(),
  'tags': z.array(z.string()),
  'published': z.boolean(),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
});

// Public catalog (customer view)
final catalogProductSchema = productSchema.pick([
  'id',
  'name',
  'description',
  'price',
  'compareAtPrice',
  'tags',
]).extend({
  'inStock': z.boolean(),  // Computed from stock
});

// Admin list view
final adminListProductSchema = productSchema.pick([
  'id',
  'sku',
  'name',
  'price',
  'stock',
  'published',
]);

// Admin detail view
final adminDetailProductSchema = productSchema.omit([
  'createdAt',
  'updatedAt',
]);

// Create product form
final createProductSchema = productSchema.omit([
  'id',
  'createdAt',
  'updatedAt',
]);

// Quick edit form
final quickEditSchema = productSchema.pick([
  'price',
  'stock',
  'published',
]);
```

---

### Blog Post

```dart
final postSchema = z.object({
  'id': z.string().uuid(),
  'slug': z.string(),
  'title': z.string(),
  'excerpt': z.string(),
  'content': z.string(),
  'coverImage': z.string().url().optional(),
  'authorId': z.string().uuid(),
  'categoryId': z.string().uuid(),
  'tags': z.array(z.string()),
  'status': z.enum(['draft', 'published', 'archived']),
  'publishedAt': z.string().datetime().optional(),
  'createdAt': z.string().datetime(),
  'updatedAt': z.string().datetime(),
  'viewCount': z.integer(),
});

// List view (preview cards)
final postPreviewSchema = postSchema.pick([
  'id',
  'slug',
  'title',
  'excerpt',
  'coverImage',
  'publishedAt',
]);

// Full post view (reader)
final postDetailSchema = postSchema.omit([
  'status',
  'viewCount',
]);

// Editor (create/edit)
final postEditorSchema = postSchema.pick([
  'title',
  'excerpt',
  'content',
  'coverImage',
  'categoryId',
  'tags',
  'status',
]);

// SEO metadata
final postSEOSchema = postSchema.pick([
  'slug',
  'title',
  'excerpt',
  'coverImage',
  'publishedAt',
]);
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Use pick for small subsets
userSchema.pick(['id', 'name']);

// ✅ Use omit for excluding few fields
userSchema.omit(['password']);

// ✅ Create semantic names
final publicUserSchema = userSchema.omit(['password', 'salt']);
final loginRequestSchema = userSchema.pick(['email', 'password']);

// ✅ Combine with extend for variations
userSchema
  .omit(['password'])
  .extend({'displayName': z.string()});
```

---

### ❌ DON'T

```dart
// ❌ Don't pick most fields (use omit instead)
userSchema.pick([
  'id',
  'email',
  'name',
  'role',
  'createdAt',
  'updatedAt',
  // ... 10 more fields
]);
// Better: userSchema.omit(['password'])

// ❌ Don't chain unnecessarily
userSchema
  .pick(['a', 'b', 'c'])
  .pick(['a', 'b']);  // Just pick(['a', 'b']) directly

// ❌ Don't pick non-existent fields
userSchema.pick(['unknownField']);  // Runtime error
```

---

## TypeScript Comparison

For TypeScript developers:

```typescript
// TypeScript
type User = {
  id: string;
  email: string;
  password: string;
};

type PublicUser = Pick<User, 'id' | 'email'>;
type LoginRequest = Pick<User, 'email' | 'password'>;
type UserWithoutPassword = Omit<User, 'password'>;
```

```dart
// Zema (similar concept)
final userSchema = z.object({
  'id': z.string(),
  'email': z.string(),
  'password': z.string(),
});

final publicUserSchema = userSchema.pick(['id', 'email']);
final loginRequestSchema = userSchema.pick(['email', 'password']);
final userWithoutPasswordSchema = userSchema.omit(['password']);
```

---

## API Reference

### pick

```dart
schema.pick(List<String> keys)
```

Returns new schema with **only** the specified fields.

---

### omit

```dart
schema.omit(List<String> keys)
```

Returns new schema **without** the specified fields.

---

## Next Steps

- [Merging Schemas →](./merging-schemas) - Combine schemas
- [Discriminated Unions →](./discriminated-unions) - Type-safe unions
- [Partial →](/docs/core/schemas/optional-nullable#partial) - Make all fields optional
