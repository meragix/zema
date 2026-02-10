---
sidebar_position: 4
description: Validate enum values and union types with Zema
---

# Enums & Unions

Validate data that must match one of several predefined values or types.

---

## Enums

### Basic Enum

```dart
final schema = z.enum(['red', 'green', 'blue']);

schema.parse('red');     // ✅ ZemaSuccess('red')
schema.parse('yellow');  // ❌ ZemaFailure (not in enum)
schema.parse(123);       // ❌ ZemaFailure (not a string)
```

---

### Enum with Custom Error Message

```dart
final colorSchema = z.enum(
  ['red', 'green', 'blue'],
  errorMessage: 'Color must be red, green, or blue',
);

colorSchema.parse('yellow');
// ❌ Error: Color must be red, green, or blue
```

---

### Enum with Numbers

```dart
final statusCodeSchema = z.enum([200, 404, 500]);

statusCodeSchema.parse(200);  // ✅ ZemaSuccess(200)
statusCodeSchema.parse(301);  // ❌ ZemaFailure (not in enum)
```

---

### Enum from Dart Enum

```dart
enum UserRole { admin, user, guest }

// Convert Dart enum to Zema enum
final roleSchema = z.enum(UserRole.values.map((e) => e.name).toList());

roleSchema.parse('admin');  // ✅ ZemaSuccess('admin')
roleSchema.parse('superadmin');  // ❌ ZemaFailure
```

Transform to Dart enum:

```dart
final roleSchema = z.enum(UserRole.values.map((e) => e.name).toList())
  .transform((value) {
    return UserRole.values.firstWhere((e) => e.name == value);
  });

final result = roleSchema.parse('admin');
// result.value is UserRole.admin (enum, not string)
```

---

### Enum in Object

```dart
final userSchema = z.object({
  'name': z.string(),
  'role': z.enum(['admin', 'user', 'guest']).default('user'),
  'status': z.enum(['active', 'inactive', 'banned']),
});

userSchema.parse({
  'name': 'Alice',
  'role': 'admin',
  'status': 'active',
});  // ✅
```

---

## Literal Values

For single literal values:

```dart
// Single literal
final trueSchema = z.literal(true);

trueSchema.parse(true);   // ✅
trueSchema.parse(false);  // ❌

// String literal
final helloSchema = z.literal('hello');

helloSchema.parse('hello');  // ✅
helloSchema.parse('world');  // ❌

// Number literal
final zeroSchema = z.literal(0);

zeroSchema.parse(0);  // ✅
zeroSchema.parse(1);  // ❌
```

---

## Unions

Unions allow multiple types for a single field.

### Basic Union

```dart
final schema = z.union([
  z.string(),
  z.integer(),
]);

schema.parse('hello');  // ✅ ZemaSuccess('hello')
schema.parse(42);       // ✅ ZemaSuccess(42)
schema.parse(true);     // ❌ ZemaFailure (not string or int)
```

---

### Union of Objects

```dart
final schema = z.union([
  z.object({
    'type': z.literal('email'),
    'email': z.string().email(),
  }),
  z.object({
    'type': z.literal('phone'),
    'phone': z.string(),
  }),
]);

schema.parse({
  'type': 'email',
  'email': 'alice@example.com',
});  // ✅

schema.parse({
  'type': 'phone',
  'phone': '+1234567890',
});  // ✅
```

---

### Discriminated Unions

Use a discriminator field to distinguish between types:

```dart
enum EventType { userCreated, userDeleted, userUpdated }

final eventSchema = z.union([
  z.object({
    'type': z.literal('userCreated'),
    'userId': z.string(),
    'email': z.string().email(),
  }),
  z.object({
    'type': z.literal('userDeleted'),
    'userId': z.string(),
    'reason': z.string(),
  }),
  z.object({
    'type': z.literal('userUpdated'),
    'userId': z.string(),
    'changes': z.object({
      'email': z.string().email().optional(),
      'name': z.string().optional(),
    }),
  }),
]).discriminatedBy('type');

// Validates based on 'type' field
eventSchema.parse({
  'type': 'userCreated',
  'userId': '123',
  'email': 'alice@example.com',
});  // ✅
```

---

### Extension Types with Discriminated Unions

```dart
// Base event
abstract class Event {
  String get type;
  String get userId;
}

// User created event
extension type UserCreatedEvent(Map<String, dynamic> _) 
    implements ZemaObject, Event {
  String get type => _['type'];
  String get userId => _['userId'];
  String get email => _['email'];
}

// User deleted event
extension type UserDeletedEvent(Map<String, dynamic> _)
    implements ZemaObject, Event {
  String get type => _['type'];
  String get userId => _['userId'];
  String get reason => _['reason'];
}

// Factory to create correct type
Event parseEvent(Map<String, dynamic> json) {
  final result = eventSchema.parse(json);
  
  if (result.isFailure) {
    throw ArgumentError('Invalid event: ${result.errors}');
  }
  
  final data = result.value as Map<String, dynamic>;
  
  return switch (data['type']) {
    'userCreated' => UserCreatedEvent(data),
    'userDeleted' => UserDeletedEvent(data),
    _ => throw ArgumentError('Unknown event type'),
  };
}
```

---

## Nullable Unions

Union with null:

```dart
final schema = z.union([
  z.string(),
  z.null_(),
]);

// Or use nullable shorthand
final schema = z.string().nullable();

schema.parse('hello');  // ✅ ZemaSuccess('hello')
schema.parse(null);     // ✅ ZemaSuccess(null)
schema.parse(123);      // ❌ ZemaFailure
```

---

## Optional Unions

Union with undefined/missing:

```dart
final schema = z.object({
  'name': z.string(),
  'email': z.union([
    z.string().email(),
    z.undefined(),
  ]),
});

// Or use optional shorthand
final schema = z.object({
  'name': z.string(),
  'email': z.string().email().optional(),
});

schema.parse({
  'name': 'Alice',
  'email': 'alice@example.com',
});  // ✅

schema.parse({
  'name': 'Alice',
  // email omitted
});  // ✅
```

---

## Real-World Examples

### API Response with Multiple Formats

```dart
// API can return success or error
final apiResponseSchema = z.union([
  // Success response
  z.object({
    'status': z.literal('success'),
    'data': z.object({
      'id': z.integer(),
      'name': z.string(),
    }),
  }),
  
  // Error response
  z.object({
    'status': z.literal('error'),
    'message': z.string(),
    'code': z.integer(),
  }),
]);

// Usage
final result = apiResponseSchema.parse(apiResponse);

if (result.isSuccess) {
  final response = result.value as Map<String, dynamic>;
  
  if (response['status'] == 'success') {
    final data = response['data'];
    print('Success: ${data['name']}');
  } else {
    final message = response['message'];
    print('Error: $message');
  }
}
```

---

### Payment Method

```dart
enum PaymentMethod { creditCard, paypal, bankTransfer }

final paymentSchema = z.union([
  z.object({
    'method': z.literal('creditCard'),
    'cardNumber': z.string().regex(RegExp(r'^\d{16}$')),
    'cvv': z.string().regex(RegExp(r'^\d{3}$')),
    'expiryDate': z.string().regex(RegExp(r'^\d{2}/\d{2}$')),
  }),
  
  z.object({
    'method': z.literal('paypal'),
    'email': z.string().email(),
  }),
  
  z.object({
    'method': z.literal('bankTransfer'),
    'accountNumber': z.string(),
    'routingNumber': z.string(),
  }),
]).discriminatedBy('method');

// Extension Types
extension type CreditCardPayment(Map<String, dynamic> _) implements ZemaObject {
  String get method => _['method'];
  String get cardNumber => _['cardNumber'];
  String get cvv => _['cvv'];
  String get expiryDate => _['expiryDate'];
}

extension type PaypalPayment(Map<String, dynamic> _) implements ZemaObject {
  String get method => _['method'];
  String get email => _['email'];
}

extension type BankTransferPayment(Map<String, dynamic> _) implements ZemaObject {
  String get method => _['method'];
  String get accountNumber => _['accountNumber'];
  String get routingNumber => _['routingNumber'];
}
```

---

### Form Input (String or Number)

```dart
// User can input either format
final ageSchema = z.union([
  z.integer(),
  z.string().regex(RegExp(r'^\d+$')).transform((s) => int.parse(s)),
]);

ageSchema.parse(25);    // ✅ ZemaSuccess(25)
ageSchema.parse('25');  // ✅ ZemaSuccess(25)  (transformed)
ageSchema.parse('abc'); // ❌ ZemaFailure
```

---

## Performance Tips

### Order Matters in Unions

```dart
// ❌ Slow: Complex types first
z.union([
  z.object({...}),  // Checked first (expensive)
  z.string(),       // Checked second
]);

// ✅ Fast: Simple types first
z.union([
  z.string(),       // Checked first (cheap)
  z.object({...}),  // Checked second
]);
```

Zema tries each type in order until one succeeds.

---

### Use Discriminated Unions When Possible

```dart
// ❌ Slower: Must try each schema
z.union([
  z.object({'type': z.literal('a'), ...}),
  z.object({'type': z.literal('b'), ...}),
  z.object({'type': z.literal('c'), ...}),
]);

// ✅ Faster: Discriminator field shortcuts validation
z.union([...]).discriminatedBy('type');
```

---

## API Reference

### Enum Methods

| Method | Description | Example |
|--------|-------------|---------|
| `z.enum(values)` | Create enum schema | `z.enum(['a', 'b'])` |
| `z.literal(value)` | Single literal value | `z.literal('hello')` |

### Union Methods

| Method | Description | Example |
|--------|-------------|---------|
| `z.union(schemas)` | Union of schemas | `z.union([z.string(), z.integer()])` |
| `.discriminatedBy(key)` | Use discriminator | `z.union([...]).discriminatedBy('type')` |

---

## Next Steps

- [Optional & Nullable →](./optional-nullable) - Handle missing data
- [Refinements →](./refinements) - Custom validation rules
- [Custom Types →](./custom-types) - Define your own validators
