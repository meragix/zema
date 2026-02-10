---
sidebar_position: 2
description: Master error handling with ZemaResult and ZemaIssue
---

# Error Handling

Learn how to handle validation errors elegantly and effectively.

---

## ZemaResult Structure

`ZemaResult` is a sealed class with two variants:

```dart
sealed class ZemaResult<T> {
  // Success variant
  ZemaSuccess(T value)
  
  // Failure variant
  ZemaFailure(List<ZemaIssue> errors)
}
```

---

## ZemaSuccess

Represents successful validation:

```dart
final result = z.string().parse('hello');

// result is ZemaSuccess<String>
result.isSuccess   // true
result.isFailure   // false
result.value       // 'hello'
result.errors      // [] (empty list)
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isSuccess` | `bool` | Always `true` |
| `isFailure` | `bool` | Always `false` |
| `value` | `T` | The validated value |
| `errors` | `List<ZemaIssue>` | Always empty `[]` |

---

## ZemaFailure

Represents failed validation:

```dart
final result = z.integer().parse('not a number');

// result is ZemaFailure<int>
result.isSuccess   // false
result.isFailure   // true
result.errors      // [ZemaIssue(...)]
// result.value    // ❌ Throws StateError
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isSuccess` | `bool` | Always `false` |
| `isFailure` | `bool` | Always `true` |
| `value` | `T` | ❌ Throws `StateError` |
| `errors` | `List<ZemaIssue>` | List of validation errors |

---

## ZemaIssue

Each validation error is represented as a `ZemaIssue`:

```dart
class ZemaIssue {
  final ZemaIssueCode code;      // Error type
  final String message;          // Human-readable message
  final List<String> path;       // Path to invalid field
  final dynamic received;        // The invalid value
}
```

### Example

```dart
final schema = z.object({
  'user': z.object({
    'email': z.string().email(),
  }),
});

final result = schema.parse({
  'user': {
    'email': 'not-an-email',
  },
});

final issue = result.errors.first;

issue.code      // ZemaIssueCode.invalidEmail
issue.message   // 'Invalid email format'
issue.path      // ['user', 'email']
issue.received  // 'not-an-email'
```

---

## ZemaIssueCode

Programmatic error codes for handling specific error types:

```dart
enum ZemaIssueCode {
  // Type errors
  invalidType,          // Expected X, got Y
  
  // String validations
  tooShort,            // String too short
  tooLong,             // String too long
  invalidEmail,        // Invalid email format
  invalidUrl,          // Invalid URL format
  invalidUuid,         // Invalid UUID format
  invalidRegex,        // Regex pattern mismatch
  
  // Number validations
  tooSmall,            // Number too small
  tooLarge,            // Number too large
  notInteger,          // Expected integer
  notFinite,           // Infinity or NaN
  
  // Array validations
  tooFew,              // Array too short
  tooMany,             // Array too long
  
  // Object validations
  missingKey,          // Required field missing
  unknownKey,          // Extra field in strict mode
  
  // General
  required,            // Field is required
  custom,              // Custom validation failed
}
```

### Usage

```dart
switch (issue.code) {
  case ZemaIssueCode.invalidEmail:
    showError('Please enter a valid email');
    
  case ZemaIssueCode.tooShort:
    showError('Input is too short');
    
  case ZemaIssueCode.custom:
    showError(issue.message);  // Use custom message
    
  default:
    showError('Validation failed');
}
```

---

## Error Paths

The `path` property shows exactly where the error occurred:

### Flat Object

```dart
final schema = z.object({
  'email': z.string().email(),
});

final result = schema.parse({'email': 'invalid'});

result.errors.first.path  // ['email']
```

---

### Nested Object

```dart
final schema = z.object({
  'user': z.object({
    'profile': z.object({
      'email': z.string().email(),
    }),
  }),
});

final result = schema.parse({
  'user': {
    'profile': {
      'email': 'invalid',
    },
  },
});

result.errors.first.path  // ['user', 'profile', 'email']
```

---

### Array

```dart
final schema = z.array(z.integer());

final result = schema.parse([1, 'two', 3]);

result.errors.first.path  // ['1']  (index of invalid item)
```

---

### Nested Array

```dart
final schema = z.object({
  'users': z.array(
    z.object({
      'email': z.string().email(),
    }),
  ),
});

final result = schema.parse({
  'users': [
    {'email': 'valid@example.com'},
    {'email': 'invalid'},  // Error here
  ],
});

result.errors.first.path  // ['users', '1', 'email']
```

---

## Handling Multiple Errors

Zema collects **all errors** during validation:

```dart
final schema = z.object({
  'email': z.string().email(),
  'age': z.integer().min(18),
  'name': z.string().min(2),
});

final result = schema.parse({
  'email': 'invalid',
  'age': 15,
  'name': 'A',
});

// result.errors has 3 items
for (final error in result.errors) {
  print('${error.path.join('.')}: ${error.message}');
}

// Output:
// email: Invalid email format
// age: Must be at least 18
// name: Must be at least 2 characters
```

---

## Display Errors to Users

### Group by Field

```dart
Map<String, String> getFieldErrors(List<ZemaIssue> errors) {
  final fieldErrors = <String, String>{};
  
  for (final error in errors) {
    final field = error.path.isEmpty ? 'root' : error.path.join('.');
    fieldErrors[field] = error.message;
  }
  
  return fieldErrors;
}

// Usage
final result = schema.parse(data);

if (result.isFailure) {
  final fieldErrors = getFieldErrors(result.errors);
  
  // Show in UI
  emailField.error = fieldErrors['email'];
  ageField.error = fieldErrors['age'];
}
```

---

### Show All Errors

```dart
void showValidationErrors(List<ZemaIssue> errors) {
  final message = errors.map((error) {
    final field = error.path.join('.');
    return '• $field: ${error.message}';
  }).join('\n');
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Validation Errors'),
      content: Text(message),
    ),
  );
}
```

---

### First Error Only

```dart
void showFirstError(List<ZemaIssue> errors) {
  if (errors.isEmpty) return;
  
  final first = errors.first;
  final field = first.path.join('.');
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$field: ${first.message}')),
  );
}
```

---

## Error Recovery

### Provide Defaults

```dart
final schema = z.object({
  'count': z.integer().default(0),
  'active': z.boolean().default(true),
});

final result = schema.parse({
  'count': 'invalid',  // ❌ Invalid
  // active missing
});

// Uses defaults for invalid/missing fields
if (result.isSuccess) {
  result.value['count']   // 0 (default)
  result.value['active']  // true (default)
}
```

---

### Partial Validation

Allow some fields to fail:

```dart
final schema = z.object({
  'required': z.string(),
  'optional1': z.string().optional(),
  'optional2': z.integer().optional(),
});

final result = schema.parse({
  'required': 'value',
  'optional1': 'invalid-int',  // Wrong type but optional
});

// required is present and valid ✅
// optional fields can be invalid/missing ✅
```

---

### Fallback Values

```dart
T getValidatedOrFallback<T>(
  ZemaResult<T> result,
  T fallback,
) {
  return result.when(
    success: (value) => value,
    failure: (_) => fallback,
  );
}

// Usage
final count = getValidatedOrFallback(
  z.integer().parse(data),
  0,  // Fallback if validation fails
);
```

---

## Logging Errors

### To Console

```dart
void logValidationError(String operation, List<ZemaIssue> errors) {
  print('❌ Validation failed in $operation:');
  for (final error in errors) {
    print('   ${error.path.join('.')}: ${error.message}');
    if (error.received != null) {
      print('   Received: ${error.received}');
    }
  }
}

// Usage
final result = userSchema.parse(apiData);

if (result.isFailure) {
  logValidationError('fetchUser', result.errors);
}
```

---

### To Monitoring Service (Sentry)

```dart
void reportValidationError(String context, List<ZemaIssue> errors) {
  final errorData = errors.map((e) => {
    'path': e.path.join('.'),
    'code': e.code.name,
    'message': e.message,
    'received': e.received?.toString(),
  }).toList();
  
  Sentry.captureMessage(
    'Validation failed: $context',
    level: SentryLevel.warning,
    extra: {
      'errors': errorData,
      'count': errors.length,
    },
  );
}
```

---

## Custom Error Messages

### Per-Validator

```dart
z.string()
  .min(5, 'Username must be at least 5 characters')
  .max(20, 'Username cannot exceed 20 characters')
  .regex(
    RegExp(r'^[a-zA-Z0-9_]+$'),
    'Username can only contain letters, numbers, and underscores',
  );
```

---

### Per-Schema

```dart
final schema = z.object({
  'email': z.string().email(),
}).refine(
  (data) => data['email']?.contains('@company.com') ?? false,
  message: 'Must use company email address',
  path: ['email'],
);
```

---

## Error Translation (i18n)

```dart
String translateError(ZemaIssue error, String locale) {
  final translations = {
    'en': {
      ZemaIssueCode.invalidEmail: 'Invalid email format',
      ZemaIssueCode.tooShort: 'Too short',
      ZemaIssueCode.required: 'Required field',
    },
    'fr': {
      ZemaIssueCode.invalidEmail: 'Format d\'email invalide',
      ZemaIssueCode.tooShort: 'Trop court',
      ZemaIssueCode.required: 'Champ requis',
    },
  };
  
  return translations[locale]?[error.code] ?? error.message;
}

// Usage
for (final error in result.errors) {
  final translated = translateError(error, 'fr');
  showError(translated);
}
```

---

## Real-World Example

```dart
Future<void> handleApiResponse(Response response) async {
  final result = userSchema.parse(response.data);
  
  switch (result) {
    case ZemaSuccess(:final value):
      // Success - save to database
      await saveUser(value);
      showSnackBar('User saved successfully');
      
    case ZemaFailure(:final errors):
      // Failure - handle gracefully
      
      // 1. Log to monitoring
      Sentry.captureMessage(
        'Invalid API response',
        extra: {'errors': errors.map((e) => e.toJson()).toList()},
      );
      
      // 2. Show user-friendly message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Data Error'),
          content: Text(
            'The server returned invalid data. Please try again later.',
          ),
        ),
      );
      
      // 3. Log detailed errors for debugging
      if (kDebugMode) {
        for (final error in errors) {
          print('${error.path.join('.')}: ${error.message}');
        }
      }
  }
}
```

---

## API Reference

### ZemaResult Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `when()` | `R` | Pattern match success/failure |
| `maybeWhen()` | `R` | Pattern match with default |
| `onSuccess()` | `void` | Execute on success |
| `onError()` | `void` | Execute on failure |
| `mapTo()` | `ZemaResult<R>` | Transform to another type |

### ZemaIssue Properties

| Property | Type | Description |
|----------|------|-------------|
| `code` | `ZemaIssueCode` | Error type |
| `message` | `String` | Human message |
| `path` | `List<String>` | Field path |
| `received` | `dynamic` | Invalid value |

---

## Next Steps

- [Custom Validators →](./custom-validators) - Write custom validation logic
- [Async Validation →](./async-validation) - Validate with async operations
- [Refinements →](/docs/core/schemas/refinements) - Advanced validation rules
