import 'package:hive_ce/hive_ce.dart';
import 'package:zema/zema.dart';

import '../exceptions/hive_exception.dart';

/// Called when [ZemaBox.get] fails to parse a stored document.
///
/// Return a non-null fallback to recover gracefully (e.g. a placeholder or a
/// cached value). Return `null` to receive [ZemaBox.get]'s `defaultValue`
/// instead.
///
/// ```dart
/// onParseError: (key, rawData, issues) {
///   logger.warn('corrupt doc $key: $issues');
///   return {'id': key, 'name': 'Unknown', 'email': 'unknown@example.com'};
/// }
/// ```
typedef OnHiveParseError<T extends Object> = T? Function(
  String key,
  Map<String, dynamic> rawData,
  List<ZemaIssue> issues,
);

/// Called when a stored document fails the current schema, giving you a chance
/// to transform the raw data before re-validation.
///
/// Inspect [rawData] to determine what fields are missing or renamed, then
/// return the corrected map. The result is validated against the current schema
/// and written back to Hive automatically if it passes.
///
/// Make each migration idempotent (check before modifying) so it is safe to
/// call on documents already at the current schema version.
///
/// ```dart
/// migrate: (rawData) {
///   // v1 -> v2: add 'role' field
///   if (!rawData.containsKey('role')) rawData['role'] = 'user';
///   // v2 -> v3: rename 'email' -> 'emailAddress'
///   if (rawData.containsKey('email') && !rawData.containsKey('emailAddress')) {
///     rawData['emailAddress'] = rawData.remove('email');
///   }
///   return rawData;
/// }
/// ```
typedef ZemaHiveMigration = Map<String, dynamic> Function(
  Map<String, dynamic> rawData,
);

/// A type-safe wrapper around a Hive [Box] that validates every read and write
/// through a [ZemaSchema].
///
/// Documents are stored as raw [Map<String, dynamic>] — no [TypeAdapter], no
/// code generation required.
///
/// ## Create
///
/// ```dart
/// final box = await Hive.openBox('users');
/// final userBox = box.withZema(userSchema);
/// ```
///
/// ## Write — validated before storage
///
/// ```dart
/// await userBox.put('alice', {
///   'name': 'Alice',
///   'email': 'alice@example.com',
/// });
/// ```
///
/// ## Read — validated on retrieval
///
/// ```dart
/// final user = userBox.get('alice');
/// // Map<String, dynamic>? — null if key does not exist or validation fails
/// ```
///
/// ## Migration
///
/// ```dart
/// final userBox = box.withZema(
///   userSchemaV2,
///   migrate: (rawData) {
///     if (!rawData.containsKey('role')) rawData['role'] = 'user';
///     return rawData;
///   },
/// );
/// ```
final class ZemaBox<T extends Object> {
  ZemaBox({
    required Box box,
    required ZemaSchema<dynamic, T> schema,
    ZemaHiveMigration? migrate,
    OnHiveParseError<T>? onParseError,
  })  : _box = box,
        _schema = schema,
        _migrate = migrate,
        _onParseError = onParseError;

  final Box _box;
  final ZemaSchema<dynamic, T> _schema;
  final ZemaHiveMigration? _migrate;
  final OnHiveParseError<T>? _onParseError;

  // ---------------------------------------------------------------------------
  // Write operations
  // ---------------------------------------------------------------------------

  /// Validates [value] against the schema and writes it to Hive.
  ///
  /// Throws [ZemaHiveException] if validation fails — nothing is written.
  Future<void> put(String key, T value) async {
    final map = _toMap(value);

    switch (_schema.safeParse(map)) {
      case ZemaSuccess():
        await _box.put(key, map);
      case ZemaFailure(:final errors):
        throw ZemaHiveException(
          'Validation failed for key "$key"',
          key: key,
          issues: errors,
          receivedData: map,
        );
    }
  }

  /// Validates all [entries] and writes them atomically.
  ///
  /// Every entry is validated before any write occurs. Throws
  /// [ZemaHiveException] on the first validation failure — nothing is written.
  Future<void> putAll(Map<String, T> entries) async {
    final validated = <String, Map<String, dynamic>>{};

    for (final entry in entries.entries) {
      final map = _toMap(entry.value);

      switch (_schema.safeParse(map)) {
        case ZemaSuccess():
          validated[entry.key] = map;
        case ZemaFailure(:final errors):
          throw ZemaHiveException(
            'Validation failed for key "${entry.key}"',
            key: entry.key,
            issues: errors,
            receivedData: map,
          );
      }
    }

    await _box.putAll(validated);
  }

  // ---------------------------------------------------------------------------
  // Read operations
  // ---------------------------------------------------------------------------

  /// Reads the document at [key] and validates it through the schema.
  ///
  /// Returns [defaultValue] when:
  /// - The key does not exist.
  /// - The stored value is not a [Map].
  /// - Validation fails and neither [migrate] nor [onParseError] recovers it.
  ///
  /// When [migrate] is provided and validation fails, the callback is applied
  /// to the raw data. If the migrated data passes validation it is written
  /// back to Hive automatically.
  T? get(String key, {T? defaultValue}) {
    final raw = _box.get(key);
    if (raw == null) return defaultValue;
    if (raw is! Map) return defaultValue;

    final data = Map<String, dynamic>.from(raw);
    return _parseOrMigrate(key, data, defaultValue);
  }

  /// All valid documents in the box, skipping entries that fail validation.
  Iterable<T> get values {
    return _box.keys
        .whereType<String>()
        .map((key) => get(key))
        .whereType<T>();
  }

  /// All valid documents keyed by their Hive key.
  Map<String, T> toMap() {
    final result = <String, T>{};
    for (final key in _box.keys.whereType<String>()) {
      final value = get(key);
      if (value != null) result[key] = value;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Delete operations
  // ---------------------------------------------------------------------------

  /// Deletes the document at [key].
  Future<void> delete(String key) => _box.delete(key);

  /// Deletes all documents at [keys].
  Future<void> deleteAll(List<String> keys) => _box.deleteAll(keys);

  /// Deletes all documents from the box.
  Future<void> clear() async {
    await _box.clear();
  }

  // ---------------------------------------------------------------------------
  // Box utilities
  // ---------------------------------------------------------------------------

  /// Number of documents in the box.
  int get length => _box.length;

  /// Whether the box is empty.
  bool get isEmpty => _box.isEmpty;

  /// Whether the box has at least one document.
  bool get isNotEmpty => _box.isNotEmpty;

  /// Whether [key] exists in the box.
  bool containsKey(String key) => _box.containsKey(key);

  /// All keys stored in the box.
  Iterable<String> get keys => _box.keys.whereType<String>();

  /// Compacts the underlying Hive box to reclaim disk space.
  Future<void> compact() => _box.compact();

  /// Closes the underlying Hive box.
  Future<void> close() => _box.close();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  T? _parseOrMigrate(
    String key,
    Map<String, dynamic> data,
    T? defaultValue,
  ) {
    final result = _schema.safeParse(data);

    if (result is ZemaSuccess<T>) return result.value;

    final errors = (result as ZemaFailure<T>).errors;
    final migrate = _migrate;

    if (migrate != null) {
      try {
        final migrated = migrate(data);
        final migratedResult = _schema.safeParse(migrated);

        if (migratedResult is ZemaSuccess<T>) {
          // Write the migrated document back asynchronously.
          _box.put(key, migrated);
          return migratedResult.value;
        }

        final migratedErrors = (migratedResult as ZemaFailure<T>).errors;
        return _onParseError?.call(key, migrated, migratedErrors) ??
            defaultValue;
      } catch (_) {
        // Migration callback threw — fall through to onParseError.
      }
    }

    return _onParseError?.call(key, data, errors) ?? defaultValue;
  }

  /// Extracts the underlying [Map<String, dynamic>] from [value].
  ///
  /// Safe when [T] is an extension type on [Map<String, dynamic>] since
  /// extension types share the same runtime representation as their base type.
  Map<String, dynamic> _toMap(T value) => value as Map<String, dynamic>;
}
