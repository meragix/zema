# zema_firestore

[![pub.dev](https://img.shields.io/pub/v/zema_firestore.svg)](https://pub.dev/packages/zema_firestore)

Zema schema validation integration for [Cloud Firestore](https://pub.dev/packages/cloud_firestore).

Hooks into Firestore's native `withConverter` API so every document read is automatically validated against a Zema schema. One line to wire up a collection: all reads, streams, and queries return validated data.

## Installation

```yaml
dependencies:
  zema: ^0.4.0
  zema_firestore: ^0.1.0
  cloud_firestore: ^5.0.0
```

## Quick start

```dart
import 'package:zema/zema.dart';
import 'package:zema_firestore/zema_firestore.dart';

final userSchema = z.object({
  'id': z.string(),
  'name': z.string().min(1),
  'email': z.string().email(),
  'createdAt': zTimestamp(),
});

final usersRef = FirebaseFirestore.instance
    .collection('users')
    .withZema(userSchema);

// Read: validated automatically
final snapshot = await usersRef.doc('abc').get();
final user = snapshot.data(); // Map<String, dynamic>, always valid

// Stream: each document validated as it arrives
usersRef.snapshots().listen((snap) {
  for (final doc in snap.docs) {
    print(doc.data()['email']); // safe
  }
});

// Write
await usersRef.doc('abc').set({
  'name': 'Alice',
  'email': 'alice@example.com',
  'createdAt': DateTime.now(), // written as Timestamp automatically
});
```

## How it works

`withZema(schema)` calls Firestore's `withConverter` with a `ZemaFirestoreConverter<T>` that:

1. Injects the document ID into the data map under `'id'` (configurable).
2. Runs `schema.safeParse(data)` on every read.
3. Converts `DateTime` fields to `Timestamp` on every write.
4. Throws `ZemaFirestoreException` on schema mismatch, or calls `onParseError` if provided.

## Firebase-specific schemas

Use these instead of standard Zema primitives for Firestore-specific types:

```dart
final schema = z.object({
  'createdAt': zTimestamp(),   // Timestamp | DateTime  →  DateTime
  'location':  zGeoPoint(),   // GeoPoint
  'authorRef': zDocumentRef(), // DocumentReference
  'avatar':    zBlob(),        // Blob
});
```

`zTimestamp()` accepts both `Timestamp` (from Firestore) and `DateTime` (from app code) and always produces a `DateTime`.

## Error handling

```dart
final usersRef = FirebaseFirestore.instance
    .collection('users')
    .withZema(
      userSchema,
      onParseError: (snapshot, error, stackTrace) {
        // Log to your error tracker
        Sentry.captureException(error, stackTrace: stackTrace);
        // Return a fallback or null to rethrow
        return {'id': snapshot.id, 'name': 'Unknown', 'email': 'unknown@example.com', 'createdAt': DateTime(2000)};
      },
    );
```

When no `onParseError` is provided, a `ZemaFirestoreException` is thrown with:

- `path`: Firestore document path
- `documentId`: document ID
- `issues`: `List<ZemaIssue>` from Zema
- `receivedData`: raw document data for debugging

## Configuration

| Parameter           | Type               | Default  | Description                                               |
|---------------------|--------------------|----------|-----------------------------------------------------------|
| `schema`            | `ZemaSchema<_, T>` | required | Schema used to validate each document                     |
| `validateWrites`    | `bool`             | `false`  | Validate the map through schema before writing            |
| `injectDocumentId`  | `bool`             | `true`   | Inject document ID into the data map before parsing       |
| `documentIdField`   | `String`           | `'id'`   | Key used for the injected document ID                     |
| `onParseError`      | `OnParseError<T>?` | `null`   | Fallback callback on parse failure                        |

## Works with Query and DocumentReference

```dart
// Query
final active = FirebaseFirestore.instance
    .collection('users')
    .where('isActive', isEqualTo: true)
    .withZema(userSchema);

final snap = await active.get();
for (final doc in snap.docs) {
  print(doc.data()['name']); // validated
}

// DocumentReference
final ref = FirebaseFirestore.instance
    .collection('users')
    .doc('abc')
    .withZema(userSchema);

await ref.set({'name': 'Alice', 'email': 'alice@example.com', 'createdAt': DateTime.now()});
```

## Related packages

- [`zema`](https://pub.dev/packages/zema): core schema library
- [`zema_forms`](https://pub.dev/packages/zema_forms): Flutter form integration
- [`zema_hive`](https://pub.dev/packages/zema_hive): Hive integration
