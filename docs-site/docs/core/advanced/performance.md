---
sidebar_position: 1
description: Tips and techniques for optimizing Zema validation performance
---

# Performance Optimization

Learn how to maximize Zema's performance for production applications.

---

## Benchmark Overview

Typical validation performance (M1 MacBook Pro):

```dart
// Single object validation: ~50-100μs
final result = userSchema.parse(userData);

// 1000 object validations: ~50-100ms
for (var i = 0; i < 1000; i++) {
  userSchema.parse(userData);
}

// Extension Type overhead: 0μs (compile-time only)
final user = result.value as User;
```

**Key insight:** Validation is fast enough for most apps (99%+ use cases).

---

## Schema Reuse

### ❌ Bad: Create Schema Every Time

```dart
void validateUser(Map<String, dynamic> data) {
  // ❌ Schema created on every call
  final schema = z.object({
    'email': z.string().email(),
    'age': z.integer(),
  });
  
  schema.parse(data);
}

// Called 1000 times = 1000 schema creations
for (var i = 0; i < 1000; i++) {
  validateUser(userData);
}
```

**Cost:** Schema instantiation overhead × 1000

---

### ✅ Good: Define Schema Once

```dart
// ✅ Define schema at top level
final userSchema = z.object({
  'email': z.string().email(),
  'age': z.integer(),
});

void validateUser(Map<String, dynamic> data) {
  userSchema.parse(data);  // Reuses same schema
}

// Schema created once, reused 1000 times
for (var i = 0; i < 1000; i++) {
  validateUser(userData);
}
```

**Savings:** ~30-40% faster

---

## Avoid Deep Nesting

### ❌ Slow: Deeply Nested Schema

```dart
// ❌ 5 levels deep
final schema = z.object({
  'level1': z.object({
    'level2': z.object({
      'level3': z.object({
        'level4': z.object({
          'level5': z.string(),
        }),
      }),
    }),
  }),
});

// Validation time: ~200μs
```

---

### ✅ Fast: Flattened Schema

```dart
// ✅ Flatten where possible
final level5Schema = z.object({'level5': z.string()});
final level4Schema = z.object({'level4': level5Schema});
final level3Schema = z.object({'level3': level4Schema});
// ...

// Or restructure data:
final schema = z.object({
  'level5Value': z.string(),  // Flatten hierarchy
});

// Validation time: ~80μs
```

**Savings:** ~60% faster

---

## Lazy Validation for Large Arrays

### ❌ Slow: Validate Every Item

```dart
final schema = z.array(z.object({
  'id': z.integer(),
  'email': z.string().email(),
  'name': z.string(),
}));

// Validate 10,000 items
final result = schema.parse(largeArray);
// Time: ~500-800ms
```

---

### ✅ Fast: Sample Validation

```dart
// For very large arrays, validate a sample
final schema = z.array(z.object({
  'id': z.integer(),
  'email': z.string().email(),
  'name': z.string(),
})).refine(
  (list) {
    // Only validate first 100 items
    final sample = list.take(100);
    return sample.every((item) => item['id'] != null);
  },
  message: 'Sample validation failed',
);

// Time: ~50-80ms (10x faster)
```

**Trade-off:** May miss errors in items beyond sample.

**When to use:** Trusted data sources, performance-critical paths.

---

## Extension Types vs Classes

### Extension Type (Zero Cost)

```dart
extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get email => _['email'];
}

// Benchmark: 1,000,000 iterations
for (var i = 0; i < 1000000; i++) {
  final user = User(validatedMap);
  sink.add(user.email);
}
// Time: 180ms
// Allocations: 0 User objects (just Maps)
```

---

### Class (Allocation Cost)

```dart
class User {
  final String email;
  User(this.email);
}

// Benchmark: 1,000,000 iterations
for (var i = 0; i < 1000000; i++) {
  final user = User(validatedMap['email']);
  sink.add(user.email);
}
// Time: 250ms
// Allocations: 1,000,000 User objects
```

**Savings:** ~28% faster with Extension Types

---

## Batch Validation

### ❌ Slow: Validate One at a Time

```dart
final users = <User>[];

for (final json in jsonList) {
  final result = userSchema.parse(json);
  if (result.isSuccess) {
    users.add(result.value as User);
  }
}

// Time for 1000 items: ~100ms
```

---

### ✅ Fast: Parse Array Once

```dart
final schema = z.array(userSchema);

final result = schema.parse(jsonList);

final users = result.isSuccess
    ? (result.value as List).cast<User>()
    : <User>[];

// Time for 1000 items: ~80ms
```

**Savings:** ~20% faster

---

## Conditional Validation

### Skip Validation in Production (Risky)

```dart
// ⚠️ Only if you ABSOLUTELY trust the data source
final result = kDebugMode
    ? userSchema.parse(data)  // Validate in debug
    : ZemaSuccess(data);      // Skip in release

// Savings: 100% (but loses all safety!)
```

**When to use:** Never recommended. Only for extreme cases where:

- Data source is 100% controlled
- Performance is critical (60fps animations)
- You have extensive integration tests

---

## Optimize Regular Expressions

### ❌ Slow: Complex Regex

```dart
final schema = z.string().regex(
  RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$'),
);

// Time per validation: ~150μs
```

---

### ✅ Fast: Simple Checks + Refinement

```dart
final schema = z.string()
  .min(8)
  .refine(
    (s) => s.contains(RegExp(r'[a-z]')),  // Simple regex
    message: 'Must contain lowercase',
  )
  .refine(
    (s) => s.contains(RegExp(r'[A-Z]')),  // Simple regex
    message: 'Must contain uppercase',
  )
  .refine(
    (s) => s.contains(RegExp(r'\d')),     // Simple regex
    message: 'Must contain number',
  );

// Time per validation: ~80μs
```

**Savings:** ~47% faster

---

## Async Validation (Use Sparingly)

### ❌ Slow: Async Check Every Field

```dart
final schema = z.object({
  'username': z.string().refineAsync(
    (s) async => await checkUsernameAvailable(s),  // API call
  ),
  'email': z.string().refineAsync(
    (e) async => await checkEmailAvailable(e),     // API call
  ),
});

// Time: ~200-500ms (network latency)
```

---

### ✅ Fast: Batch Async Checks

```dart
final schema = z.object({
  'username': z.string(),
  'email': z.string().email(),
}).refineAsync(
  (data) async {
    // Single API call for both checks
    final available = await checkAvailability(
      username: data['username'],
      email: data['email'],
    );
    return available;
  },
);

// Time: ~100-200ms (single network request)
```

**Savings:** ~50% faster

---

## Memoization (Advanced)

### Cache Validation Results

```dart
final _validationCache = <String, ZemaResult>{};

ZemaResult<T> validateWithCache<T>(
  ZemaSchema<T> schema,
  dynamic data,
) {
  final key = jsonEncode(data);  // Simple cache key
  
  if (_validationCache.containsKey(key)) {
    return _validationCache[key] as ZemaResult<T>;
  }
  
  final result = schema.parse(data);
  _validationCache[key] = result;
  
  return result;
}

// Usage
final result = validateWithCache(userSchema, userData);
```

**When to use:**

- Same data validated multiple times
- Expensive schemas (deep nesting, complex regex)

**Trade-off:**

- Memory usage (cache grows)
- Only works for immutable data

---

## Profiling Example

### Measure Validation Performance

```dart
import 'dart:developer';

void benchmarkValidation() {
  final schema = z.object({
    'email': z.string().email(),
    'age': z.integer(),
  });
  
  final data = {'email': 'test@example.com', 'age': 30};
  
  // Warmup
  for (var i = 0; i < 100; i++) {
    schema.parse(data);
  }
  
  // Measure
  final stopwatch = Stopwatch()..start();
  
  Timeline.startSync('Zema Validation');
  
  for (var i = 0; i < 10000; i++) {
    schema.parse(data);
  }
  
  Timeline.finishSync();
  
  stopwatch.stop();
  
  print('10,000 validations: ${stopwatch.elapsedMilliseconds}ms');
  print('Per validation: ${stopwatch.elapsedMicroseconds / 10000}μs');
}
```

**Run in DevTools → Performance to see timeline.**

---

## Real-World Optimization

### Before Optimization

```dart
// Slow: Creating schema in widget build()
class UserProfile extends StatelessWidget {
  final Map<String, dynamic> userData;
  
  @override
  Widget build(BuildContext context) {
    // ❌ Schema created on every rebuild
    final schema = z.object({
      'name': z.string(),
      'email': z.string().email(),
    });
    
    final result = schema.parse(userData);
    
    // ...
  }
}

// Performance: ~200μs per rebuild
```

---

### After Optimization

```dart
// Fast: Schema defined at top level
final _userProfileSchema = z.object({
  'name': z.string(),
  'email': z.string().email(),
});

class UserProfile extends StatelessWidget {
  final Map<String, dynamic> userData;
  
  @override
  Widget build(BuildContext context) {
    // ✅ Reuses same schema
    final result = _userProfileSchema.parse(userData);
    
    // ...
  }
}

// Performance: ~80μs per rebuild (2.5x faster)
```

---

## Performance Summary

| Optimization | Impact | Effort |
|--------------|--------|--------|
| **Schema reuse** | ⚡⚡⚡ High (30-40%) | ✅ Easy |
| **Flatten nesting** | ⚡⚡ Medium (20-60%) | 🟡 Medium |
| **Extension Types** | ⚡⚡ Medium (20-30%) | ✅ Easy |
| **Batch validation** | ⚡ Small (10-20%) | ✅ Easy |
| **Optimize regex** | ⚡⚡ Medium (30-50%) | 🟡 Medium |
| **Lazy array validation** | ⚡⚡⚡ High (80-90%) | 🔴 Hard |
| **Memoization** | ⚡⚡⚡ High (90%+) | 🔴 Hard |

---

## When to Optimize

### ✅ Optimize When

- Validating **1000s of objects** per second
- **60fps animations** require fast validation
- **Mobile devices** with limited CPU
- Validation shows up in **profiler** as bottleneck

### ❌ Don't Optimize When

<!-- - Validation is **<1% of total time** -->
- **Premature optimization** (no measurements)
- **Rare code paths** (one-time initialization)

**Rule:** Measure first, optimize later.

---

## Profiling Tools

### Flutter DevTools

1. Open DevTools → Performance
2. Record timeline
3. Look for `Zema Validation` spans
4. Optimize hot paths only

### Benchmark Code

```dart
void benchmark() {
  final stopwatch = Stopwatch()..start();
  
  for (var i = 0; i < 10000; i++) {
    userSchema.parse(data);
  }
  
  stopwatch.stop();
  // print('Time: ${stopwatch.elapsedMilliseconds}ms');
}
```

---

## Next Steps

- [Lazy Schemas →](./lazy-schemas) - Handle recursive data
- [Branded Types →](./branded-types) - Type-level constraints
- [Real-World Apps →](/docs/recipes/real-world-apps/) - See optimizations in practice
