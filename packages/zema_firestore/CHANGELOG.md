## 0.3.0

- Supports `cloud_firestore` 5.x, 6.x and 7.x (`>=5.0.0 <8.0.0`). Previous releases were capped at 5.x and could not be installed alongside current FlutterFire versions.
- Requires `zema: ^0.7.0`.

## 0.2.0

- Requires `zema: ^0.6.0`.

## 0.1.0

- Initial release.
- `withZema(schema)` extension on `CollectionReference`, `DocumentReference`, and `Query`.
- `ZemaFirestoreConverter<T>`: hooks into Firestore `withConverter`, injects document ID, converts `DateTime` to `Timestamp` on writes.
- Firebase-specific schemas: `zTimestamp()`, `zGeoPoint()`, `zDocumentRef()`, `zBlob()`.
- `ZemaFirestoreException` with document path, ID, and `List<ZemaIssue>`.
- `onParseError` callback for graceful fallback on schema mismatch.
