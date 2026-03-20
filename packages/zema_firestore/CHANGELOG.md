## 0.1.0

- Initial release.
- `withZema(schema)` extension on `CollectionReference`, `DocumentReference`, and `Query`.
- `ZemaFirestoreConverter<T>` — hooks into Firestore `withConverter`, injects document ID, converts `DateTime` to `Timestamp` on writes.
- Firebase-specific schemas: `zTimestamp()`, `zGeoPoint()`, `zDocumentRef()`, `zBlob()`.
- `ZemaFirestoreException` with document path, ID, and `List<ZemaIssue>`.
- `onParseError` callback for graceful fallback on schema mismatch.
