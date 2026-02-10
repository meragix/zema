---
sidebar_position: 4
description: Perform asynchronous validation with external services
---

# Async Validation

Perform validation that requires asynchronous operations like database queries or API calls.

---

## Basic Async Validation

### refineAsync

```dart
final usernameSchema = z.string().refineAsync(
  (username) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 100));
    
    final taken = await checkUsernameTaken(username);
    
    return !taken;  // true = valid, false = invalid
  },
  message: 'Username already taken',
);

// Usage
final result = await usernameSchema.parseAsync('alice');

if (result.isSuccess) {
  print('Username available');
} else {
  print('Username taken');
}
```

**Async validation signature:**

```dart
Future<bool> refineFn(T value) async {
  // Return true if valid
  // Return false if invalid
}
```

---

## Async Validation Examples

### Check Username Availability

```dart
Future<bool> checkUsernameAvailable(String username) async {
  // API call to check username
  final response = await dio.get('/api/users/check-username', 
    queryParameters: {'username': username},
  );
  
  return response.data['available'] as bool;
}

final usernameSchema = z.string()
  .min(3)
  .max(20)
  .regex(RegExp(r'^[a-zA-Z0-9_]+$'))
  .refineAsync(
    checkUsernameAvailable,
    message: 'Username already taken',
  );

// Usage
final result = await usernameSchema.parseAsync('alice123');
```

---

### Check Email Availability

```dart
Future<bool> checkEmailAvailable(String email) async {
  final response = await dio.post('/api/auth/check-email', 
    data: {'email': email},
  );
  
  return response.data['available'] as bool;
}

final emailSchema = z.string()
  .email()
  .refineAsync(
    checkEmailAvailable,
    message: 'Email already registered',
  );
```

---

### Verify Invite Code

```dart
Future<bool> verifyInviteCode(String code) async {
  try {
    final response = await dio.get('/api/invites/$code');
    
    final invite = response.data;
    
    // Check if valid and not expired
    if (invite['used'] == true) return false;
    
    final expiresAt = DateTime.parse(invite['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) return false;
    
    return true;
  } catch (e) {
    return false;  // Code doesn't exist
  }
}

final inviteCodeSchema = z.string()
  .length(8)
  .refineAsync(
    verifyInviteCode,
    message: 'Invalid or expired invite code',
  );
```

---

## Multiple Async Validators

```dart
final registrationSchema = z.object({
  'username': z.string()
    .min(3)
    .refineAsync(
      checkUsernameAvailable,
      message: 'Username taken',
    ),
    
  'email': z.string()
    .email()
    .refineAsync(
      checkEmailAvailable,
      message: 'Email already registered',
    ),
    
  'inviteCode': z.string()
    .optional()
    .refineAsync(
      (code) async {
        if (code == null) return true;
        return verifyInviteCode(code);
      },
      message: 'Invalid invite code',
    ),
});

// Validation runs async validators in parallel
final result = await registrationSchema.parseAsync({
  'username': 'alice',
  'email': 'alice@example.com',
  'inviteCode': 'ABC12345',
});
```

---

## Async Object Validation

### Cross-Field Async Validation

```dart
final orderSchema = z.object({
  'productId': z.string(),
  'quantity': z.integer().positive(),
  'couponCode': z.string().optional(),
}).refineAsync(
  (data) async {
    // Check if product has enough stock
    final response = await dio.get('/api/products/${data['productId']}');
    final product = response.data;
    
    final requestedQty = data['quantity'] as int;
    final availableQty = product['stock'] as int;
    
    return requestedQty <= availableQty;
  },
  message: 'Insufficient stock',
  path: ['quantity'],
).refineAsync(
  (data) async {
    final coupon = data['couponCode'];
    if (coupon == null) return true;
    
    // Verify coupon is valid
    final response = await dio.get('/api/coupons/$coupon');
    return response.data['valid'] as bool;
  },
  message: 'Invalid coupon code',
  path: ['couponCode'],
);
```

---

## Debouncing Async Validation

### Debounce for Form Inputs

```dart
class DebouncedAsyncValidator {
  final Future<bool> Function(String) validator;
  final Duration delay;
  Timer? _debounceTimer;

  DebouncedAsyncValidator({
    required this.validator,
    this.delay = const Duration(milliseconds: 500),
  });

  Future<bool> validate(String value) async {
    final completer = Completer<bool>();

    _debounceTimer?.cancel();

    _debounceTimer = Timer(delay, () async {
      final result = await validator(value);
      completer.complete(result);
    });

    return completer.future;
  }

  ZemaSchema<String> get schema {
    return z.string().refineAsync(
      validate,
      message: 'Validation failed',
    );
  }
}

// Usage
final debouncedUsernameValidator = DebouncedAsyncValidator(
  validator: checkUsernameAvailable,
  delay: Duration(milliseconds: 500),
);

final usernameSchema = debouncedUsernameValidator.schema;

// In Flutter TextField
TextField(
  onChanged: (value) async {
    final result = await usernameSchema.parseAsync(value);
    
    if (result.isFailure) {
      setState(() {
        errorText = result.errors.first.message;
      });
    } else {
      setState(() {
        errorText = null;
      });
    }
  },
);
```

---

## Caching Async Results

### Cache Validation Results

```dart
class CachedAsyncValidator {
  final Future<bool> Function(String) validator;
  final Map<String, bool> _cache = {};
  final Duration cacheDuration;

  CachedAsyncValidator({
    required this.validator,
    this.cacheDuration = const Duration(minutes: 5),
  });

  Future<bool> validate(String value) async {
    // Check cache
    if (_cache.containsKey(value)) {
      return _cache[value]!;
    }

    // Call validator
    final result = await validator(value);

    // Cache result
    _cache[value] = result;

    // Clear cache after duration
    Future.delayed(cacheDuration, () {
      _cache.remove(value);
    });

    return result;
  }

  ZemaSchema<String> get schema {
    return z.string().refineAsync(
      validate,
      message: 'Validation failed',
    );
  }
}

// Usage
final cachedValidator = CachedAsyncValidator(
  validator: checkUsernameAvailable,
);

final usernameSchema = cachedValidator.schema;
```

---

## Error Handling

### Handle Network Errors

```dart
final usernameSchema = z.string().refineAsync(
  (username) async {
    try {
      final available = await checkUsernameAvailable(username);
      return available;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        // Treat timeout as valid (optimistic)
        return true;
      }
      
      // Log error
      print('Username check failed: $e');
      
      // Treat as invalid (pessimistic)
      return false;
    } catch (e) {
      // Unknown error - log and treat as valid
      print('Unexpected error: $e');
      return true;
    }
  },
  message: 'Username validation failed. Please try again.',
);
```

---

## Timeout Handling

### Add Timeout to Async Validation

```dart
Future<bool> checkUsernameWithTimeout(String username) async {
  try {
    return await checkUsernameAvailable(username)
        .timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print('Username check timed out');
            return true;  // Optimistic on timeout
          },
        );
  } catch (e) {
    print('Error checking username: $e');
    return true;  // Optimistic on error
  }
}

final usernameSchema = z.string().refineAsync(
  checkUsernameWithTimeout,
  message: 'Username already taken',
);
```

---

## Real-World Example: Registration Form

```dart
class RegistrationValidator {
  final Dio dio;

  RegistrationValidator(this.dio);

  Future<bool> checkUsernameAvailable(String username) async {
    final response = await dio.get('/api/users/check-username',
      queryParameters: {'username': username},
    ).timeout(Duration(seconds: 3));

    return response.data['available'] as bool;
  }

  Future<bool> checkEmailAvailable(String email) async {
    final response = await dio.get('/api/users/check-email',
      queryParameters: {'email': email},
    ).timeout(Duration(seconds: 3));

    return response.data['available'] as bool;
  }

  Future<bool> verifyInviteCode(String code) async {
    try {
      final response = await dio.get('/api/invites/$code')
          .timeout(Duration(seconds: 3));

      final invite = response.data;

      if (invite['used'] == true) return false;

      final expiresAt = DateTime.parse(invite['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  ZemaSchema<Map<String, dynamic>> get schema {
    return z.object({
      'username': z.string()
        .min(3, 'Minimum 3 characters')
        .max(20, 'Maximum 20 characters')
        .regex(RegExp(r'^[a-zA-Z0-9_]+$'), 'Invalid characters')
        .refineAsync(
          checkUsernameAvailable,
          message: 'Username already taken',
        ),

      'email': z.string()
        .email('Invalid email format')
        .refineAsync(
          checkEmailAvailable,
          message: 'Email already registered',
        ),

      'password': z.string()
        .min(8, 'Minimum 8 characters')
        .regex(RegExp(r'[A-Z]'), 'Must contain uppercase')
        .regex(RegExp(r'[a-z]'), 'Must contain lowercase')
        .regex(RegExp(r'[0-9]'), 'Must contain number'),

      'confirmPassword': z.string(),

      'inviteCode': z.string()
        .optional()
        .refineAsync(
          (code) async {
            if (code == null) return true;
            return verifyInviteCode(code);
          },
          message: 'Invalid or expired invite code',
        ),
    }).refine(
      (data) => data['password'] == data['confirmPassword'],
      message: 'Passwords must match',
      path: ['confirmPassword'],
    );
  }
}

// Usage in Flutter
class RegistrationForm extends StatefulWidget {
  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _validator = RegistrationValidator(Dio());
  bool _isValidating = false;
  Map<String, String> _errors = {};

  Future<void> _submit() async {
    setState(() {
      _isValidating = true;
      _errors = {};
    });

    final data = {
      'username': usernameController.text,
      'email': emailController.text,
      'password': passwordController.text,
      'confirmPassword': confirmPasswordController.text,
      'inviteCode': inviteCodeController.text.isEmpty 
          ? null 
          : inviteCodeController.text,
    };

    final result = await _validator.schema.parseAsync(data);

    setState(() {
      _isValidating = false;
    });

    if (result.isSuccess) {
      // Submit registration
      await registerUser(result.value);
    } else {
      // Show errors
      setState(() {
        _errors = {
          for (final error in result.errors)
            error.path.join('.'): error.message,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              errorText: _errors['username'],
            ),
          ),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: _errors['email'],
            ),
          ),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _errors['password'],
            ),
          ),
          TextField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              errorText: _errors['confirmPassword'],
            ),
          ),
          TextField(
            controller: inviteCodeController,
            decoration: InputDecoration(
              labelText: 'Invite Code (Optional)',
              errorText: _errors['inviteCode'],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isValidating ? null : _submit,
            child: _isValidating
                ? CircularProgressIndicator()
                : Text('Register'),
          ),
        ],
      ),
    );
  }
}
```

---

## Best Practices

### ✅ DO

```dart
// ✅ Add timeout to async validators
await checkAvailable(value).timeout(Duration(seconds: 3));

// ✅ Cache results to avoid redundant API calls
final _cache = <String, bool>{};

// ✅ Handle errors gracefully
try {
  return await validator(value);
} catch (e) {
  return true;  // Optimistic on error
}

// ✅ Debounce form inputs
DebouncedAsyncValidator(delay: Duration(milliseconds: 500));

// ✅ Show loading indicator during validation
if (_isValidating) CircularProgressIndicator();
```

---

### ❌ DON'T

```dart
// ❌ Don't use async validation for sync checks
z.string().refineAsync(
  (s) async => s.length >= 8,  // ❌ No need for async
);
// Use: z.string().min(8)

// ❌ Don't block UI without loading indicator
await schema.parseAsync(data);  // UI frozen

// ❌ Don't validate on every keystroke without debounce
TextField(onChanged: (v) async {
  await schema.parseAsync(v);  // API call on every key!
});

// ❌ Don't ignore errors silently
await validator(value).catchError((_) => true);  // ❌ Silent fail
```

---

## Performance Tips

### Parallel Async Validation

```dart
// ❌ Slow: Sequential validation
await usernameSchema.parseAsync(username);  // Wait
await emailSchema.parseAsync(email);        // Then wait

// ✅ Fast: Parallel validation
final results = await Future.wait([
  usernameSchema.parseAsync(username),
  emailSchema.parseAsync(email),
]);
```

---

## API Reference

### refineAsync

```dart
schema.refineAsync(
  Future<bool> Function(T value) test,
  {
    String? message,
    List<String>? path,
  }
)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `test` | `Future<bool> Function(T)` | Async validation (return true if valid) |
| `message` | `String?` | Error message if validation fails |
| `path` | `List<String>?` | Field path for error (for objects) |

### parseAsync

```dart
Future<ZemaResult<T>> parseAsync(dynamic data)
```

Returns a `Future<ZemaResult<T>>` after running all async validators.

---

## Next Steps

- [Custom Validators →](./custom-validators) - Sync custom validation
- [Refinements →](/docs/core/schemas/refinements) - Add validation rules
<!-- - [Forms →](/docs/plugins/flutter_zema/guides/async-validation) - Async validation in forms -->
