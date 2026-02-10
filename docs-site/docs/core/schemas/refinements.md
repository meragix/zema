---
sidebar_position: 6
description: Add custom validation rules with refinements
---

# Refinements

Refinements allow you to add custom validation logic beyond built-in validators.

---

## Basic Refinement

### Simple Refinement

```dart
final schema = z.string().refine(
  (value) => value.contains('@'),
  message: 'Must contain @ symbol',
);

schema.parse('hello@example.com');  // ✅
schema.parse('hello');               // ❌ Must contain @ symbol
```

---

### Refinement Function

```dart
final schema = z.integer().refine(
  (value) => value % 2 == 0,
  message: 'Must be an even number',
);

schema.parse(42);  // ✅ Even number
schema.parse(43);  // ❌ Must be an even number
```

**Refinement signature:**

```dart
bool refineFn(T value) {
  // Return true if valid
  // Return false if invalid
}
```

---

## Refinement with Path

Specify which field the error applies to:

```dart
final schema = z.object({
  'password': z.string(),
  'confirmPassword': z.string(),
}).refine(
  (data) => data['password'] == data['confirmPassword'],
  message: 'Passwords must match',
  path: ['confirmPassword'],  // Error shown on this field
);

schema.parse({
  'password': 'secret123',
  'confirmPassword': 'different',
});
// ❌ Error on 'confirmPassword': Passwords must match
```

---

## Multiple Refinements

Chain multiple refinements:

```dart
final passwordSchema = z.string()
  .min(8, 'Minimum 8 characters')
  .refine(
    (s) => s.contains(RegExp(r'[A-Z]')),
    message: 'Must contain uppercase letter',
  )
  .refine(
    (s) => s.contains(RegExp(r'[a-z]')),
    message: 'Must contain lowercase letter',
  )
  .refine(
    (s) => s.contains(RegExp(r'[0-9]')),
    message: 'Must contain number',
  )
  .refine(
    (s) => s.contains(RegExp(r'[!@#$%^&*]')),
    message: 'Must contain special character',
  );

passwordSchema.parse('weak');
// ❌ Multiple errors:
//   - Minimum 8 characters
//   - Must contain uppercase letter
//   - Must contain number
//   - Must contain special character
```

---

## Cross-Field Validation

### Password Confirmation

```dart
final registrationSchema = z.object({
  'email': z.string().email(),
  'password': z.string().min(8),
  'confirmPassword': z.string(),
}).refine(
  (data) => data['password'] == data['confirmPassword'],
  message: 'Passwords must match',
  path: ['confirmPassword'],
);
```

---

### Date Range

```dart
final dateRangeSchema = z.object({
  'startDate': z.string().datetime(),
  'endDate': z.string().datetime(),
}).refine(
  (data) {
    final start = DateTime.parse(data['startDate']);
    final end = DateTime.parse(data['endDate']);
    return end.isAfter(start);
  },
  message: 'End date must be after start date',
  path: ['endDate'],
);
```

---

### Conditional Required

```dart
final userSchema = z.object({
  'role': z.enum(['admin', 'user']),
  'adminKey': z.string().optional(),
}).refine(
  (data) {
    // If admin, adminKey is required
    if (data['role'] == 'admin') {
      return data['adminKey'] != null && data['adminKey'] != '';
    }
    return true;
  },
  message: 'Admin role requires admin key',
  path: ['adminKey'],
);

userSchema.parse({
  'role': 'admin',
  // adminKey missing
});
// ❌ Admin role requires admin key
```

---

### Budget Constraint

```dart
final orderSchema = z.object({
  'items': z.array(z.object({
    'price': z.double().positive(),
    'quantity': z.integer().positive(),
  })),
  'maxBudget': z.double().positive(),
}).refine(
  (data) {
    final items = data['items'] as List;
    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
    return total <= data['maxBudget'];
  },
  message: 'Total exceeds budget',
  path: ['items'],
);
```

---

## Refinement with Context

### Access Parent Data

```dart
final productSchema = z.object({
  'basePrice': z.double().positive(),
  'discount': z.double().min(0).max(1),
  'finalPrice': z.double().positive(),
}).refine(
  (data) {
    final expected = data['basePrice'] * (1 - data['discount']);
    final actual = data['finalPrice'];
    return (expected - actual).abs() < 0.01;  // Float comparison
  },
  message: 'Final price does not match calculation',
  path: ['finalPrice'],
);
```

---

## Complex Business Rules

### Inventory Check

```dart
final inventorySchema = z.object({
  'quantity': z.integer().nonNegative(),
  'reserved': z.integer().nonNegative(),
  'available': z.integer().nonNegative(),
}).refine(
  (data) => data['available'] == data['quantity'] - data['reserved'],
  message: 'Available must equal quantity minus reserved',
  path: ['available'],
).refine(
  (data) => data['reserved'] <= data['quantity'],
  message: 'Cannot reserve more than available quantity',
  path: ['reserved'],
);
```

---

### Credit Card

```dart
bool luhnCheck(String cardNumber) {
  final digits = cardNumber.replaceAll(RegExp(r'\D'), '').split('');
  if (digits.length < 13) return false;

  var sum = 0;
  var isEven = false;

  for (var i = digits.length - 1; i >= 0; i--) {
    var digit = int.parse(digits[i]);

    if (isEven) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }

    sum += digit;
    isEven = !isEven;
  }

  return sum % 10 == 0;
}

final cardSchema = z.string()
  .regex(RegExp(r'^\d{13,19}$'), 'Invalid card number format')
  .refine(
    luhnCheck,
    message: 'Invalid card number (failed Luhn check)',
  );

cardSchema.parse('4532015112830366');  // ✅ Valid Visa
cardSchema.parse('1234567890123456');  // ❌ Failed Luhn check
```

---

### Email Domain Whitelist

```dart
final corporateEmailSchema = z.string()
  .email()
  .refine(
    (email) {
      final allowedDomains = ['company.com', 'partner.com'];
      final domain = email.split('@').last;
      return allowedDomains.contains(domain);
    },
    message: 'Must use corporate email domain',
  );

corporateEmailSchema.parse('alice@company.com');   // ✅
corporateEmailSchema.parse('alice@gmail.com');     // ❌
```

---

## Refinement Performance

### Early Return

```dart
// ✅ Good: Check cheap conditions first
final schema = z.string()
  .refine((s) => s.isNotEmpty, message: 'Required')  // Fast
  .refine((s) => s.length >= 8, message: 'Min 8 chars')  // Fast
  .refine(
    (s) => expensiveValidation(s),  // Expensive check last
    message: 'Complex validation failed',
  );
```

---

### Avoid Redundant Checks

```dart
// ❌ Bad: Redundant length check
z.string()
  .min(8)  // Already checks length
  .refine(
    (s) => s.length >= 8,  // Redundant!
    message: 'Min 8 chars',
  );

// ✅ Good: Use built-in validators
z.string().min(8);
```

---

## Refinement Error Messages

### Dynamic Error Messages

```dart
final schema = z.integer().refine(
  (value) => value >= 18,
  message: (value) => 'Must be 18 or older. You are $value.',
);

schema.parse(15);
// ❌ Must be 18 or older. You are 15.
```

---

### Detailed Error Context

```dart
final schema = z.object({
  'items': z.array(z.object({
    'name': z.string(),
    'price': z.double(),
  })),
  'total': z.double(),
}).refine(
  (data) {
    final items = data['items'] as List;
    final calculatedTotal = items.fold<double>(
      0,
      (sum, item) => sum + item['price'],
    );
    return (calculatedTotal - data['total']).abs() < 0.01;
  },
  message: (data) {
    final items = data['items'] as List;
    final calculatedTotal = items.fold<double>(
      0,
      (sum, item) => sum + item['price'],
    );
    return 'Total mismatch: calculated $calculatedTotal but got ${data['total']}';
  },
  path: ['total'],
);
```

---

## Real-World Examples

### Age Verification

```dart
final ageVerificationSchema = z.object({
  'birthDate': z.string().datetime(),
  'country': z.string(),
}).refine(
  (data) {
    final birthDate = DateTime.parse(data['birthDate']);
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    
    // Different age limits by country
    final minAge = switch (data['country']) {
      'US' => 21,
      'UK' => 18,
      'JP' => 20,
      _ => 18,
    };
    
    return age >= minAge;
  },
  message: (data) {
    final birthDate = DateTime.parse(data['birthDate']);
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    final minAge = switch (data['country']) {
      'US' => 21,
      'UK' => 18,
      'JP' => 20,
      _ => 18,
    };
    return 'Must be at least $minAge years old in ${data['country']}. You are $age.';
  },
  path: ['birthDate'],
);
```

---

### Shipping Address

```dart
final shippingSchema = z.object({
  'country': z.string(),
  'postalCode': z.string(),
}).refine(
  (data) {
    // Validate postal code format per country
    return switch (data['country']) {
      'US' => RegExp(r'^\d{5}(-\d{4})?$').hasMatch(data['postalCode']),
      'CA' => RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$').hasMatch(data['postalCode']),
      'UK' => RegExp(r'^[A-Z]{1,2}\d{1,2} \d[A-Z]{2}$').hasMatch(data['postalCode']),
      _ => true,  // No validation for other countries
    };
  },
  message: 'Invalid postal code format for selected country',
  path: ['postalCode'],
);
```

---

### File Upload

```dart
final fileUploadSchema = z.object({
  'filename': z.string(),
  'size': z.integer().positive(),
  'mimeType': z.string(),
}).refine(
  (data) {
    const maxSize = 10 * 1024 * 1024;  // 10MB
    return data['size'] <= maxSize;
  },
  message: 'File size must be less than 10MB',
  path: ['size'],
).refine(
  (data) {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];
    return allowedTypes.contains(data['mimeType']);
  },
  message: 'File type not allowed. Only JPEG, PNG, GIF, and PDF are accepted.',
  path: ['mimeType'],
).refine(
  (data) {
    final filename = data['filename'] as String;
    final ext = filename.split('.').last.toLowerCase();
    final mimeType = data['mimeType'] as String;
    
    // Verify extension matches MIME type
    return switch (mimeType) {
      'image/jpeg' => ext == 'jpg' || ext == 'jpeg',
      'image/png' => ext == 'png',
      'image/gif' => ext == 'gif',
      'application/pdf' => ext == 'pdf',
      _ => false,
    };
  },
  message: 'File extension does not match file type',
  path: ['filename'],
);
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Use refinements for business logic
z.integer().refine((n) => n % 2 == 0, message: 'Must be even');

// ✅ Provide clear error messages
.refine((s) => s.contains('@'), message: 'Email must contain @');

// ✅ Specify error path for objects
.refine(
  (data) => data['a'] == data['b'],
  message: 'Values must match',
  path: ['b'],  // Error goes to field 'b'
);

// ✅ Check cheap conditions first
z.string()
  .min(8)  // Fast check
  .refine((s) => expensiveCheck(s), message: '...');  // Expensive check last
```

---

### ❌ DON'T

```dart
// ❌ Don't use refinements for built-in validators
z.string().refine((s) => s.length >= 8, message: 'Min 8 chars');
// Use: z.string().min(8)

// ❌ Don't do heavy computation in refinements
z.string().refine((s) {
  // Heavy operation on every validation
  final result = expensiveDatabaseQuery(s);
  return result.isValid;
});
// Consider: Cache results or use async validation

// ❌ Don't throw exceptions in refinements
z.integer().refine((n) {
  if (n < 0) throw Exception('Negative!');  // ❌ Don't throw
  return true;
});
// Instead: Return false to indicate validation failure
```

---

## API Reference

### Refine Method

```dart
schema.refine(
  bool Function(T value) test,
  {
    String? message,
    String Function(T value)? messageFn,
    List<String>? path,
  }
)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `test` | `bool Function(T)` | Validation function (return true if valid) |
| `message` | `String?` | Static error message |
| `messageFn` | `String Function(T)?` | Dynamic error message with value |
| `path` | `List<String>?` | Field path for error (for objects) |

---

## Next Steps

- [Custom Types →](./custom-types) - Define completely custom schemas
- [Async Validation →](/docs/core/validation/async-validation) - Async refinements
- [Transforms →](/docs/core/transformations/transforms) - Transform validated data
