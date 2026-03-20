# zema_hive

[![pub.dev](https://img.shields.io/pub/v/zema_hive.svg)](https://pub.dev/packages/zema_hive)

Zema schema validation integration for [Hive CE](https://pub.dev/packages/hive_ce).

Type-safe local storage without TypeAdapters or code generation. Wrap any Hive `Box` with a Zema schema — every write is validated before reaching disk, every read is validated before reaching your code.

## Installation

```yaml
dependencies:
  zema: ^0.4.0
  zema_hive: ^0.1.0
  hive_ce: ^2.19.3
```

## Quick start

```dart
import 'package:hive_ce/hive_ce.dart';
import 'package:zema/zema.dart';
import 'package:zema_hive/zema_hive.dart';

final userSchema = z.object({
  'id':    z.string(),
  'name':  z.string().min(1),
  'email': z.string().email(),
});

final box = await Hive.openBox('users');
final userBox = box.withZema(userSchema);

// Write — validated before storage, throws ZemaHiveException on failure
await userBox.put('alice', {
  'id':    'alice',
  'name':  'Alice',
  'email': 'alice@example.com',
});

// Read — validated on retrieval
final user = userBox.get('alice'); // Map<String, dynamic>?
print(user?['name']); // Alice
```

## How it works

`withZema(schema)` wraps a `Box` in a `ZemaBox<T>` that:

1. Runs `schema.safeParse(data)` on every `put()` — throws `ZemaHiveException` if it fails, nothing is written.
2. Runs `schema.safeParse(data)` on every `get()` — returns `null` (or `defaultValue`) if it fails.
3. Applies a [migrate] callback when `get()` fails validation, then re-validates and writes the result back automatically.

## Extension types

Use Dart extension types to get named field access without any runtime overhead:

```dart
extension type User(Map<String, dynamic> _) {
  String get id => _['id'] as String;
  String get name => _['name'] as String;
  String get email => _['email'] as String;
}

final userBox = box.withZema<User>(userSchema);

await userBox.put('alice', User({'id': 'alice', 'name': 'Alice', 'email': 'alice@example.com'}));

final user = userBox.get('alice'); // User?
print(user?.name); // Alice
```

## Migration

When your schema evolves, pass a `migrate` callback. It is called automatically when a stored document fails the current schema. The result is re-validated and written back to Hive if it passes.

```dart
final userBox = box.withZema(
  userSchemaV2,
  migrate: (rawData) {
    // v1 -> v2: back-fill 'role'
    if (!rawData.containsKey('role')) rawData['role'] = 'user';
    // v2 -> v3: rename 'email' -> 'emailAddress'
    if (rawData.containsKey('email') && !rawData.containsKey('emailAddress')) {
      rawData['emailAddress'] = rawData.remove('email');
    }
    return rawData;
  },
);

final user = userBox.get('legacy'); // migrated and written back automatically
```

Make each migration idempotent (check before modifying) — the callback is called once per failing document, and the migrated version is written back, so subsequent reads no longer trigger it.

## Error handling

```dart
final userBox = box.withZema(
  userSchema,
  onParseError: (key, rawData, issues) {
    // Log to your error tracker
    Sentry.captureMessage('Corrupt doc $key: $issues');
    // Return a fallback or null to use defaultValue
    return {'id': key, 'name': 'Unknown', 'email': 'unknown@example.com'};
  },
);
```

`onParseError` is called when `get()` fails validation and either no `migrate` callback is provided, or migration also fails. Return a non-null value to recover, or return `null` to fall back to `defaultValue`.

## ZemaHiveException

Thrown by `put()` and `putAll()` when validation fails:

```dart
try {
  await userBox.put('bad', {'id': 'bad', 'name': '', 'email': 'not-valid'});
} on ZemaHiveException catch (e) {
  print(e.key);    // 'bad'
  print(e.issues); // List<ZemaIssue>
}
```

`putAll()` validates all entries before writing any of them — if one entry fails, nothing is written.

## Configuration

| Parameter      | Type                    | Default | Description                                                |
|----------------|-------------------------|---------|------------------------------------------------------------|
| `schema`       | `ZemaSchema<_, T>`      | required | Schema used to validate each document                      |
| `migrate`      | `ZemaHiveMigration?`    | `null`  | Called on `get()` when validation fails; result is re-validated and written back |
| `onParseError` | `OnHiveParseError<T>?`  | `null`  | Fallback callback when `get()` fails (after migration, if any) |

## API reference

| Method / Property       | Description                                                      |
|-------------------------|------------------------------------------------------------------|
| `put(key, value)`       | Validate and write; throws on failure                            |
| `putAll(entries)`       | Validate all, then write atomically; throws on first failure     |
| `get(key)`              | Read and validate; migrate if needed; return null on failure     |
| `values`                | All valid documents; invalid entries are silently skipped        |
| `toMap()`               | All valid documents as `Map<String, T>`                          |
| `delete(key)`           | Delete a document                                                |
| `deleteAll(keys)`       | Delete multiple documents                                        |
| `clear()`               | Delete all documents                                             |
| `keys`                  | All stored keys                                                  |
| `length`                | Number of stored entries                                         |
| `containsKey(key)`      | Whether a key exists                                             |
| `compact()`             | Compact the underlying Hive box                                  |
| `close()`               | Close the underlying Hive box                                    |

## Related packages

- [`zema`](https://pub.dev/packages/zema) — core schema library
- [`zema_forms`](https://pub.dev/packages/zema_forms) — Flutter form integration
- [`zema_firestore`](https://pub.dev/packages/zema_firestore) — Cloud Firestore integration
- [`zema_dio`](https://pub.dev/packages/zema_dio) — Dio response validation
- [`zema_http`](https://pub.dev/packages/zema_http) — package:http response validation
