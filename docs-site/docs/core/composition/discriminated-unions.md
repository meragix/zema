---
sidebar_position: 3
description: Type-safe unions with discriminator fields
---

# Discriminated Unions

Create type-safe unions that switch on a discriminator field.

---

## Basic Discriminated Union

```dart
final eventSchema = z.union([
  z.object({
    'type': z.literal('click'),
    'x': z.integer(),
    'y': z.integer(),
  }),
  z.object({
    'type': z.literal('keypress'),
    'key': z.string(),
  }),
]).discriminatedBy('type');

// Validates based on 'type' field
eventSchema.parse({
  'type': 'click',
  'x': 100,
  'y': 200,
});  // ✅

eventSchema.parse({
  'type': 'keypress',
  'key': 'Enter',
});  // ✅
```

**Discriminator:** A field (usually 'type') that determines which schema to use.

---

## Why Discriminated Unions?

### Without Discriminator (Slow)

```dart
// ❌ Tries each schema until one succeeds
z.union([
  z.object({...}),  // Check schema 1
  z.object({...}),  // Check schema 2
  z.object({...}),  // Check schema 3
]);
```

---

### With Discriminator (Fast)

```dart
// ✅ Checks 'type' field, uses correct schema immediately
z.union([
  z.object({'type': z.literal('a'), ...}),
  z.object({'type': z.literal('b'), ...}),
  z.object({'type': z.literal('c'), ...}),
]).discriminatedBy('type');
```

**Performance:** Discriminated unions are **much faster** for large unions.

---

## Real-World Examples

### API Events

```dart
final apiEventSchema = z.union([
  // User created event
  z.object({
    'type': z.literal('user.created'),
    'userId': z.string().uuid(),
    'email': z.string().email(),
    'timestamp': z.string().datetime(),
  }),
  
  // User deleted event
  z.object({
    'type': z.literal('user.deleted'),
    'userId': z.string().uuid(),
    'reason': z.string(),
    'timestamp': z.string().datetime(),
  }),
  
  // User updated event
  z.object({
    'type': z.literal('user.updated'),
    'userId': z.string().uuid(),
    'changes': z.object({
      'email': z.string().email().optional(),
      'name': z.string().optional(),
    }),
    'timestamp': z.string().datetime(),
  }),
]).discriminatedBy('type');

// Extension Types
extension type UserCreatedEvent(Map<String, dynamic> _) implements ZemaObject {
  String get type => _['type'];
  String get userId => _['userId'];
  String get email => _['email'];
  DateTime get timestamp => DateTime.parse(_['timestamp']);
}

extension type UserDeletedEvent(Map<String, dynamic> _) implements ZemaObject {
  String get type => _['type'];
  String get userId => _['userId'];
  String get reason => _['reason'];
  DateTime get timestamp => DateTime.parse(_['timestamp']);
}

// Usage
void handleEvent(Map<String, dynamic> eventData) {
  final result = apiEventSchema.parse(eventData);
  
  if (result.isSuccess) {
    final event = result.value as Map<String, dynamic>;
    
    switch (event['type']) {
      case 'user.created':
        final created = UserCreatedEvent(event);
        print('User created: ${created.email}');
        
      case 'user.deleted':
        final deleted = UserDeletedEvent(event);
        print('User deleted: ${deleted.reason}');
        
      case 'user.updated':
        print('User updated');
    }
  }
}
```

---

### Payment Methods

```dart
final paymentMethodSchema = z.union([
  // Credit card
  z.object({
    'method': z.literal('credit_card'),
    'cardNumber': z.string().regex(RegExp(r'^\d{16}$')),
    'cvv': z.string().regex(RegExp(r'^\d{3}$')),
    'expiryDate': z.string().regex(RegExp(r'^\d{2}/\d{2}$')),
    'billingAddress': z.object({
      'street': z.string(),
      'city': z.string(),
      'zipCode': z.string(),
    }),
  }),
  
  // PayPal
  z.object({
    'method': z.literal('paypal'),
    'email': z.string().email(),
  }),
  
  // Bank transfer
  z.object({
    'method': z.literal('bank_transfer'),
    'accountNumber': z.string(),
    'routingNumber': z.string(),
    'bankName': z.string(),
  }),
  
  // Cryptocurrency
  z.object({
    'method': z.literal('crypto'),
    'currency': z.enum(['BTC', 'ETH', 'USDT']),
    'walletAddress': z.string(),
  }),
]).discriminatedBy('method');

// Extension Types
extension type CreditCardPayment(Map<String, dynamic> _) implements ZemaObject {
  String get method => _['method'];
  String get cardNumber => _['cardNumber'];
  String get cvv => _['cvv'];
  String get expiryDate => _['expiryDate'];
  Map<String, dynamic> get billingAddress => _['billingAddress'];
}

extension type PayPalPayment(Map<String, dynamic> _) implements ZemaObject {
  String get method => _['method'];
  String get email => _['email'];
}

// Usage
Future<void> processPayment(Map<String, dynamic> paymentData) async {
  final result = paymentMethodSchema.parse(paymentData);
  
  if (result.isFailure) {
    throw ValidationException(result.errors);
  }
  
  final payment = result.value as Map<String, dynamic>;
  
  switch (payment['method']) {
    case 'credit_card':
      final card = CreditCardPayment(payment);
      await processCreditCard(card);
      
    case 'paypal':
      final paypal = PayPalPayment(payment);
      await processPayPal(paypal);
      
    case 'bank_transfer':
      await processBankTransfer(payment);
      
    case 'crypto':
      await processCrypto(payment);
  }
}
```

---

### Notification Types

```dart
final notificationSchema = z.union([
  // Email notification
  z.object({
    'type': z.literal('email'),
    'to': z.string().email(),
    'subject': z.string(),
    'body': z.string(),
    'html': z.boolean().default(false),
  }),
  
  // SMS notification
  z.object({
    'type': z.literal('sms'),
    'to': z.string(),  // Phone number
    'message': z.string().max(160),
  }),
  
  // Push notification
  z.object({
    'type': z.literal('push'),
    'deviceToken': z.string(),
    'title': z.string(),
    'body': z.string(),
    'data': z.object({}).optional(),
  }),
  
  // In-app notification
  z.object({
    'type': z.literal('in_app'),
    'userId': z.string().uuid(),
    'message': z.string(),
    'priority': z.enum(['low', 'medium', 'high']).default('medium'),
  }),
]).discriminatedBy('type');
```

---

### Form Input Types

```dart
final formFieldSchema = z.union([
  // Text input
  z.object({
    'type': z.literal('text'),
    'name': z.string(),
    'label': z.string(),
    'placeholder': z.string().optional(),
    'defaultValue': z.string().optional(),
    'maxLength': z.integer().optional(),
  }),
  
  // Number input
  z.object({
    'type': z.literal('number'),
    'name': z.string(),
    'label': z.string(),
    'min': z.double().optional(),
    'max': z.double().optional(),
    'step': z.double().optional(),
  }),
  
  // Select dropdown
  z.object({
    'type': z.literal('select'),
    'name': z.string(),
    'label': z.string(),
    'options': z.array(z.object({
      'value': z.string(),
      'label': z.string(),
    })),
    'multiple': z.boolean().default(false),
  }),
  
  // Checkbox
  z.object({
    'type': z.literal('checkbox'),
    'name': z.string(),
    'label': z.string(),
    'defaultChecked': z.boolean().default(false),
  }),
  
  // File upload
  z.object({
    'type': z.literal('file'),
    'name': z.string(),
    'label': z.string(),
    'accept': z.string().optional(),  // MIME types
    'multiple': z.boolean().default(false),
    'maxSize': z.integer().optional(),  // Bytes
  }),
]).discriminatedBy('type');
```

---

### State Machine

```dart
final orderStateSchema = z.union([
  // Pending state
  z.object({
    'status': z.literal('pending'),
    'createdAt': z.string().datetime(),
  }),
  
  // Processing state
  z.object({
    'status': z.literal('processing'),
    'startedAt': z.string().datetime(),
    'estimatedCompletion': z.string().datetime(),
  }),
  
  // Completed state
  z.object({
    'status': z.literal('completed'),
    'completedAt': z.string().datetime(),
    'result': z.object({
      'orderId': z.string(),
      'total': z.double(),
    }),
  }),
  
  // Failed state
  z.object({
    'status': z.literal('failed'),
    'failedAt': z.string().datetime(),
    'error': z.object({
      'code': z.string(),
      'message': z.string(),
    }),
    'retryable': z.boolean(),
  }),
  
  // Cancelled state
  z.object({
    'status': z.literal('cancelled'),
    'cancelledAt': z.string().datetime(),
    'reason': z.string(),
  }),
]).discriminatedBy('status');
```

---

## Pattern Matching with Discriminated Unions

### Using Switch

```dart
void handlePayment(Map<String, dynamic> payment) {
  final result = paymentMethodSchema.parse(payment);
  
  if (result.isSuccess) {
    final method = result.value as Map<String, dynamic>;
    
    switch (method['method']) {
      case 'credit_card':
        print('Processing credit card');
        
      case 'paypal':
        print('Processing PayPal');
        
      case 'bank_transfer':
        print('Processing bank transfer');
        
      case 'crypto':
        print('Processing crypto');
    }
  }
}
```

---

### Factory Pattern

```dart
abstract class Payment {
  factory Payment.fromJson(Map<String, dynamic> json) {
    final result = paymentMethodSchema.parse(json);
    
    if (result.isFailure) {
      throw ValidationException(result.errors);
    }
    
    final data = result.value as Map<String, dynamic>;
    
    return switch (data['method']) {
      'credit_card' => CreditCardPayment(data),
      'paypal' => PayPalPayment(data),
      'bank_transfer' => BankTransferPayment(data),
      'crypto' => CryptoPayment(data),
      _ => throw ArgumentError('Unknown payment method'),
    };
  }
}
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Use literal types for discriminator
z.object({
  'type': z.literal('user_created'),  // Literal value
  ...
})

// ✅ Use discriminatedBy for performance
z.union([...]).discriminatedBy('type');

// ✅ Use consistent discriminator field name
// All use 'type' or all use 'kind', not mixed

// ✅ Provide all possible values
z.union([
  z.object({'type': z.literal('a'), ...}),
  z.object({'type': z.literal('b'), ...}),
  z.object({'type': z.literal('c'), ...}),
]);
```

---

### ❌ DON'T

```dart
// ❌ Don't use non-literal discriminator
z.object({
  'type': z.string(),  // ❌ Should be z.literal('value')
  ...
})

// ❌ Don't mix discriminator field names
z.union([
  z.object({'type': z.literal('a'), ...}),
  z.object({'kind': z.literal('b'), ...}),  // ❌ Different field
]);

// ❌ Don't forget discriminatedBy
z.union([...]);  // ❌ Missing .discriminatedBy('type')
```

---

## API Reference

### discriminatedBy

```dart
z.union([...]).discriminatedBy(String fieldName)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `fieldName` | `String` | Name of discriminator field |

**Returns:** `ZemaSchema<T>` (union schema)

---

## Next Steps

- [Merging Schemas →](./merging-schemas) - Combine schemas
- [Picking & Omitting →](./picking-omitting) - Select fields
- [Custom Types →](/docs/core/schemas/custom-types) - Define custom schemas
