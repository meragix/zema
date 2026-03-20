## 0.1.0

- Initial release.
- `withZema(schema)` extension on Hive `Box` — wraps it in a `ZemaBox<T>`.
- `ZemaBox.put()` and `ZemaBox.putAll()` — validate before writing; throw `ZemaHiveException` on failure.
- `ZemaBox.get()` — validate on read; apply `migrate` callback automatically when validation fails.
- `ZemaBox.values` and `ZemaBox.toMap()` — iterate all valid documents, silently skip invalid ones.
- `ZemaHiveMigration` callback — transform stored documents to match the current schema; migrated data is written back to Hive.
- `OnHiveParseError` callback — graceful fallback when read validation fails.
- `ZemaHiveException` with key, `List<ZemaIssue>`, and raw data for debugging.
