import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:zema/zema.dart';

import '../exceptions/firestore_exception.dart';

/// Callback invoked when [ZemaFirestoreConverter.fromFirestore] fails.
///
/// Return a non-null fallback value to recover gracefully (e.g. a placeholder
/// object or a cached version). Return `null` to let the exception propagate.
///
/// ```dart
/// onParseError: (snapshot, error, stackTrace) {
///   Sentry.captureException(error, stackTrace: stackTrace);
///   return User.placeholder(id: snapshot.id);
/// }
/// ```
typedef OnParseError<T> = T? Function(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  Object error,
  StackTrace stackTrace,
);

/// Connects a [ZemaSchema] to Firestore's [withConverter] API.
///
/// Handles:
/// - Document ID injection into the data map before parsing.
/// - Timestamp conversion: [DateTime] fields are written as [Timestamp].
/// - Optional write validation (validates the map before [toFirestore]).
/// - Graceful error recovery via [onParseError].
///
/// Do not use this class directly. Use the [withZema] extension methods on
/// [CollectionReference], [DocumentReference], and [Query] instead.
final class ZemaFirestoreConverter<T> {
  const ZemaFirestoreConverter({
    required this.schema,
    this.validateWrites = false,
    this.injectDocumentId = true,
    this.documentIdField = 'id',
    this.onParseError,
  });

  /// The schema used to validate and parse document data.
  final ZemaSchema<dynamic, T> schema;

  /// When `true`, [toFirestore] validates the map through [schema] before
  /// writing. Useful during development. Disable in production to avoid
  /// the overhead of double-parsing writes.
  final bool validateWrites;

  /// When `true`, the document ID is injected into the data map under
  /// [documentIdField] before parsing in [fromFirestore], and removed
  /// from the map in [toFirestore].
  final bool injectDocumentId;

  /// The key used when injecting the document ID. Defaults to `'id'`.
  final String documentIdField;

  /// Called when [fromFirestore] fails. Return a fallback value to recover,
  /// or return `null` to rethrow the exception.
  final OnParseError<T>? onParseError;

  // ---------------------------------------------------------------------------
  // Firestore converter callbacks
  // ---------------------------------------------------------------------------

  /// Parses a [DocumentSnapshot] into [T] using [schema].
  ///
  /// Steps:
  /// 1. Checks that the document exists.
  /// 2. Optionally injects the document ID.
  /// 3. Runs [schema.safeParse].
  /// 4. On failure, invokes [onParseError] or rethrows.
  T fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    try {
      final data = snapshot.data();

      if (data == null) {
        throw ZemaFirestoreException(
          'Document does not exist',
          path: snapshot.reference.path,
          documentId: snapshot.id,
        );
      }

      final enriched = _injectId(data, snapshot.id);

      switch (schema.safeParse(enriched)) {
        case ZemaSuccess(:final value):
          return value;
        case ZemaFailure(:final errors):
          throw ZemaFirestoreException(
            'Schema validation failed',
            path: snapshot.reference.path,
            documentId: snapshot.id,
            issues: errors,
            receivedData: enriched,
          );
      }
    } catch (error, stackTrace) {
      final fallback = onParseError?.call(snapshot, error, stackTrace);
      if (fallback != null) return fallback;

      debugPrint(
        '[zema_firestore] parse error at ${snapshot.reference.path}: $error',
      );
      rethrow;
    }
  }

  /// Converts [value] to a [Map] for Firestore.
  ///
  /// Steps:
  /// 1. Casts [value] to [Map<String, dynamic>]. Safe when [T] is an
  ///    extension type on [Map<String, dynamic>] (same runtime representation).
  /// 2. Optionally validates via [schema] when [validateWrites] is `true`.
  /// 3. Removes [documentIdField] (Firestore manages document IDs).
  /// 4. Converts [DateTime] fields to [Timestamp].
  Map<String, dynamic> toFirestore(T value, SetOptions? options) {
    // Extension types are Map<String, dynamic> at runtime — the cast is safe.
    final map = Map<String, dynamic>.from(value as Map<String, dynamic>);

    if (validateWrites) {
      switch (schema.safeParse(map)) {
        case ZemaFailure(:final errors):
          throw ZemaFirestoreException(
            'Write validation failed',
            issues: errors,
            receivedData: map,
          );
        case ZemaSuccess():
          break;
      }
    }

    if (injectDocumentId) map.remove(documentIdField);

    return _convertDates(map);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _injectId(Map<String, dynamic> data, String id) {
    if (!injectDocumentId) return data;
    return {...data, documentIdField: id};
  }

  /// Recursively converts [DateTime] values to [Timestamp] for Firestore writes.
  Map<String, dynamic> _convertDates(Map<String, dynamic> map) {
    return {
      for (final entry in map.entries) entry.key: _convertValue(entry.value),
    };
  }

  Object? _convertValue(Object? value) {
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is Map<String, dynamic>) return _convertDates(value);
    if (value is List) return [for (final item in value) _convertValue(item)];
    return value;
  }
}
