---
sidebar_position: 2
description: Validate arrays and lists with Zema
---

# Arrays

Validates `List` values. Every element is validated by the element schema. Validation is exhaustive: all element failures are collected before returning.

---

## Basic usage

```dart
final schema = z.array(z.string());

schema.parse(['a', 'b', 'c']);   // ['a', 'b', 'c']
schema.parse([1, 2, 3]);         // throws ZemaException (not strings)
schema.parse('not an array');    // throws ZemaException
```

---

## Length constraints

### Minimum length

Requires the list to have at least `n` elements. Produces `too_small`.

```dart
z.array(z.string()).min(2)

schema.parse(['a', 'b']);   // ['a', 'b']
schema.parse(['a']);         // throws ZemaException: too_small
```

---

### Maximum length

Requires the list to have at most `n` elements. Produces `too_big`.

```dart
z.array(z.string()).max(5)

schema.parse(['a', 'b', 'c']);                    // ['a', 'b', 'c']
schema.parse(['a', 'b', 'c', 'd', 'e', 'f']);    // throws ZemaException: too_big
```

---

### Exact length

Sets both minimum and maximum to `n`. Produces `too_small` or `too_big`.

```dart
z.array(z.string()).length(3)

schema.parse(['a', 'b', 'c']);   // ['a', 'b', 'c']
schema.parse(['a', 'b']);         // throws ZemaException
```

---

### Non-empty

Shorthand for `.min(1)`. Produces `too_small` on an empty list.

```dart
z.array(z.string()).nonEmpty()

schema.parse(['a']);   // ['a']
schema.parse([]);      // throws ZemaException: too_small
```

---

## Nested arrays

### Array of arrays

```dart
final schema = z.array(z.array(z.integer()));

schema.parse([
  [1, 2, 3],
  [4, 5, 6],
]);  // [[1, 2, 3], [4, 5, 6]]

schema.parse([
  [1, 2, 3],
  ['a', 'b'],  // invalid: not integers
]);  // throws ZemaException
```

---

### Array of objects

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
]);  // List<Map<String, dynamic>>

schema.parse([
  {'id': 1, 'name': 'Alice'},
  {'id': 'two', 'name': 'Bob'},  // invalid: id is not int
]);  // throws ZemaException
```

---

## Transformations

### Map elements

```dart
final schema = z.array(z.string())
  .transform((list) => list.map((s) => s.toUpperCase()).toList());

schema.parse(['hello', 'world']);   // ['HELLO', 'WORLD']
```

---

### Filter elements

```dart
final schema = z.array(z.integer())
  .transform((list) => list.where((n) => n > 0).toList());

schema.parse([1, -2, 3, -4, 5]);   // [1, 3, 5]
```

---

## Refinements

### Custom validation

```dart
final schema = z.array(z.integer())
  .refine(
    (list) => list.every((n) => n % 2 == 0),
    message: 'All numbers must be even',
  );

schema.parse([2, 4, 6]);   // [2, 4, 6]
schema.parse([2, 3, 4]);   // throws ZemaException: contains odd number
```

---

### Unique elements

```dart
final schema = z.array(z.string())
  .refine(
    (list) => list.length == list.toSet().length,
    message: 'Array must contain unique values',
  );

schema.parse(['a', 'b', 'c']);   // ['a', 'b', 'c']
schema.parse(['a', 'b', 'a']);   // throws ZemaException: duplicate 'a'
```

---

## Common patterns

### Tags array

```dart
final tagsSchema = z.array(z.string())
  .min(1)
  .max(5)
  .transform((tags) => tags.map((t) => t.toLowerCase()).toList());

tagsSchema.parse(['Flutter', 'Dart', 'Mobile']);
// ['flutter', 'dart', 'mobile']
```

---

### User list with optional field

```dart
final userSchema = z.object({
  'id': z.integer(),
  'email': z.string().email(),
  'roles': z.array(z.string()).withDefault([]),
});

final usersSchema = z.array(userSchema).min(1);

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
]);
```

---

### Pagination response

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

final result = paginatedSchema.safeParse({
  'items': [
    {'id': 1, 'title': 'First'},
    {'id': 2, 'title': 'Second'},
  ],
  'total': 100,
  'page': 1,
  'perPage': 20,
});
```

---

## Error path

Element-level issues include the element index in their path:

```dart
final schema = z.array(z.object({'name': z.string()}));
final result = schema.safeParse([
  {'name': 'Alice'},
  {'name': 42},           // invalid
]);

// ZemaIssue(code: 'invalid_type', path: [1, 'name'], ...)
// → 'name' field of element at index 1
```

---

## API reference

| Method           | Description             | Error code            |
|------------------|-------------------------|-----------------------|
| `.min(n)`        | Minimum length          | `too_small`           |
| `.max(n)`        | Maximum length          | `too_big`             |
| `.length(n)`     | Exact length            | `too_small` / `too_big` |
| `.nonEmpty()`    | At least 1 item         | `too_small`           |
| `.optional()`    | Allow null input        | N/A                   |
| `.withDefault(v)` | Substitute null with `v` | N/A                 |

---

## Next steps

- [Objects →](./objects): validate maps and nested structures
- [Refinements →](./refinements): custom validation logic
