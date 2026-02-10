---
sidebar_position: 1
description: Learn how to validate data with Zema schemas
---

# Basic Validation

Learn the fundamentals of validating data with Zema.

---

## Two Validation Methods

Zema provides two methods for validation:

### parse()

Always returns a `ZemaResult`:

```dart
final schema = z.string();

final result = schema.parse('hello');

// result is ZemaResult<String>
if (result.isSuccess) {
  print('Valid: ${result.value}');
} else {
  print('Invalid: ${result.errors}');
}
```

**Never throws exceptions** - always returns `ZemaResult`.

---

### safeParse()

Alias for `parse()` (same behavior):

```dart
final schema = z.string();

final result = schema.safeParse('hello');  // Same as parse()
```

:::info Why two methods?
For API consistency with Zod (TypeScript). In Zema, both methods are safe and return `ZemaResult`.
:::

---

## ZemaResult

Every validation returns a `ZemaResult<T>`, which is a sealed class with two variants:

### Success

```dart
final result = z.string().parse('hello');

// Type: ZemaSuccess<String>
result.isSuccess  // true
result.isFailure  // false
result.value      // 'hello'
result.errors     // []
```

---

### Failure

```dart
final result = z.integer().parse('not a number');

// Type: ZemaFailure<int>
result.isSuccess  // false
result.isFailure  // true
result.errors     // [ZemaIssue(...)]
// result.value   // ❌ Throws (no value on failure)
```

---

## Handling Results

### Pattern Matching (Recommended)

```dart
final result = userSchema.parse(data);

switch (result) {
  case ZemaSuccess(:final value):
    print('Valid user: $value');
    // Use value safely here
    
  case ZemaFailure(:final errors):
    print('Validation failed:');
    for (final error in errors) {
      print('  ${error.path.join('.')}: ${error.message}');
    }
}
```

**Why pattern matching?**

- ✅ Exhaustiveness check (compiler ensures you handle both cases)
- ✅ Type-safe access to `value` or `errors`
- ✅ Idiomatic Dart 3.0+

---

### When Method

Functional style:

```dart
final message = result.when(
  success: (value) => 'Valid: $value',
  failure: (errors) => 'Invalid: ${errors.length} errors',
);

print(message);
```

---

### If/Else

Simple conditional:

```dart
final result = schema.parse(data);

if (result.isSuccess) {
  print('Valid: ${result.value}');
} else {
  print('Invalid: ${result.errors}');
}
```

---

### Callbacks

Execute actions on success/failure:

```dart
result
  .onSuccess((value) => print('Saved: $value'))
  .onError((errors) => print('Failed: $errors'));
```

---

## Validation Flow

### Step-by-Step Example

```dart
// 1. Define schema
final userSchema = z.object({
  'email': z.string().email(),
  'age': z.integer().min(18),
});

// 2. Get data (from API, form, etc.)
final userData = {
  'email': 'alice@example.com',
  'age': 25,
};

// 3. Validate
final result = userSchema.parse(userData);

// 4. Handle result
switch (result) {
  case ZemaSuccess(:final value):
    // value is Map<String, dynamic> with validated data
    final email = value['email'] as String;
    final age = value['age'] as int;
    print('User: $email, age $age');
    
  case ZemaFailure(:final errors):
    // errors is List<ZemaIssue>
    for (final error in errors) {
      print('Error at ${error.path.join('.')}: ${error.message}');
    }
}
```

---

## Multiple Errors

Zema validates **all fields** and returns **all errors**:

```dart
final schema = z.object({
  'email': z.string().email(),
  'age': z.integer().min(18),
  'name': z.string().min(2),
});

final result = schema.parse({
  'email': 'invalid',      // ❌ Invalid email
  'age': 15,               // ❌ Too young
  'name': 'A',             // ❌ Too short
});

// result.errors contains ALL 3 errors
for (final error in result.errors) {
  print('${error.path.join('.')}: ${error.message}');
}

// Output:
// email: Invalid email format
// age: Must be at least 18
// name: Must be at least 2 characters
```

**Why all errors?**  
Better UX - show all validation errors to the user at once, not one at a time.

---

## Validation Levels

### Primitive Level

```dart
z.string().parse('hello');      // ✅
z.integer().parse(42);          // ✅
z.boolean().parse(true);        // ✅
```

---

### Array Level

```dart
z.array(z.string()).parse(['a', 'b', 'c']);  // ✅

z.array(z.integer()).parse([1, 'two', 3]);
// ❌ Error at index 1: Expected integer, got string
```

---

### Object Level

```dart
z.object({
  'name': z.string(),
  'age': z.integer(),
}).parse({
  'name': 'Alice',
  'age': 30,
});  // ✅
```

---

### Nested Level

```dart
z.object({
  'user': z.object({
    'email': z.string().email(),
    'profile': z.object({
      'bio': z.string(),
    }),
  }),
}).parse({
  'user': {
    'email': 'alice@example.com',
    'profile': {
      'bio': 'Hello world',
    },
  },
});  // ✅
```

---

## Early Return vs Collect All

### Zema's Approach: Collect All

```dart
final schema = z.object({
  'a': z.string(),
  'b': z.integer(),
  'c': z.boolean(),
});

// All invalid
final result = schema.parse({
  'a': 123,    // ❌
  'b': 'two',  // ❌
  'c': 'yes',  // ❌
});

// Returns ALL 3 errors, not just the first
result.errors.length  // 3
```

**Why?**  
Users want to see all validation errors at once, not fix one then discover the next.

---

## Validation in Practice

### API Response

```dart
Future<User> fetchUser(int id) async {
  final response = await dio.get('/users/$id');
  
  final result = userSchema.parse(response.data);
  
  switch (result) {
    case ZemaSuccess(:final value):
      return value as User;
      
    case ZemaFailure(:final errors):
      // Log validation errors
      print('Invalid API response: $errors');
      
      // Throw custom exception
      throw ApiValidationException(
        'Server returned invalid user data',
        errors: errors,
      );
  }
}
```

---

### Form Validation

```dart
void submitForm() {
  final formData = {
    'email': emailController.text,
    'password': passwordController.text,
  };
  
  final result = loginSchema.parse(formData);
  
  switch (result) {
    case ZemaSuccess(:final value):
      // Submit to server
      await login(value);
      
    case ZemaFailure(:final errors):
      // Show errors in UI
      for (final error in errors) {
        final field = error.path.first;
        showFieldError(field, error.message);
      }
  }
}
```

---

### Firestore Document

```dart
Future<void> saveUser(User user) async {
  // Validate before saving
  final result = userSchema.parse(user._);
  
  if (result.isFailure) {
    throw ArgumentError('Invalid user data: ${result.errors}');
  }
  
  // Safe to save
  await firestore.collection('users').doc(user.id).set(result.value);
}
```

---

## Type Inference

Zema preserves type information:

```dart
final stringSchema = z.string();
final result = stringSchema.parse('hello');

// result is ZemaResult<String>
if (result.isSuccess) {
  String value = result.value;  // ✅ Type: String
}

final intSchema = z.integer();
final result2 = intSchema.parse(42);

// result2 is ZemaResult<int>
if (result2.isSuccess) {
  int value = result2.value;  // ✅ Type: int
}
```

---

## Common Mistakes

### ❌ Not Handling Failure

```dart
// ❌ Bad: Assumes success
final result = schema.parse(data);
print(result.value);  // 💥 Crashes if validation failed
```

```dart
// ✅ Good: Handle both cases
final result = schema.parse(data);

if (result.isSuccess) {
  print(result.value);
} else {
  print('Validation failed: ${result.errors}');
}
```

---

### ❌ Accessing value Without Check

```dart
// ❌ Bad: Direct access
final user = userSchema.parse(data).value;  // 💥 Throws if invalid
```

```dart
// ✅ Good: Pattern match
switch (userSchema.parse(data)) {
  case ZemaSuccess(:final value):
    final user = value;
  case ZemaFailure(:final errors):
    print('Invalid: $errors');
}
```

---

### ❌ Ignoring Errors

```dart
// ❌ Bad: Silent failure
final result = schema.parse(data);
if (result.isSuccess) {
  // do something
}
// What if it failed? 🤷
```

```dart
// ✅ Good: Handle failures
final result = schema.parse(data);

switch (result) {
  case ZemaSuccess(:final value):
    // Handle success
    
  case ZemaFailure(:final errors):
    // Log or show errors
    print('Validation failed: $errors');
}
```

---

## Performance Considerations

### Reuse Schemas

```dart
// ❌ Bad: Create schema every time
void validate(Map data) {
  final schema = z.object({...});  // Created every call
  schema.parse(data);
}

// ✅ Good: Create once, reuse
final userSchema = z.object({...});

void validate(Map data) {
  userSchema.parse(data);  // Reuses same schema
}
```

---

### Validation is Fast

```dart
// Validation of 1000 objects: ~5ms
for (var i = 0; i < 1000; i++) {
  userSchema.parse(userData);
}

// Overhead per validation: ~5μs (microseconds)
// Negligible in real-world apps
```

---

## Next Steps

- [Error Handling →](./error-handling) - Deep dive into ZemaResult and ZemaIssue
- [Custom Validators →](./custom-validators) - Write your own validation logic
- [Async Validation →](./async-validation) - Validate with async operations
