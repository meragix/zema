import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zema/zema.dart';

import '../core/firestore_converter.dart';

/// Adds [withZema] to [Query].
extension ZemaQueryExtension on Query<Map<String, dynamic>> {
  /// Returns a typed [Query<T>] that parses and validates each document
  /// in the result set through [schema].
  ///
  /// ```dart
  /// final activeUsers = FirebaseFirestore.instance
  ///     .collection('users')
  ///     .where('isActive', isEqualTo: true)
  ///     .orderBy('createdAt', descending: true)
  ///     .withZema<User>(userSchema);
  ///
  /// final snapshot = await activeUsers.get();
  /// for (final doc in snapshot.docs) {
  ///   final user = doc.data(); // User is already validated
  /// }
  /// ```
  Query<T> withZema<T>(
    ZemaSchema<dynamic, T> schema, {
    bool validateWrites = false,
    bool injectDocumentId = true,
    String documentIdField = 'id',
    OnParseError<T>? onParseError,
  }) {
    final converter = ZemaFirestoreConverter<T>(
      schema: schema,
      validateWrites: validateWrites,
      injectDocumentId: injectDocumentId,
      documentIdField: documentIdField,
      onParseError: onParseError,
    );
    return withConverter<T>(
      fromFirestore: converter.fromFirestore,
      toFirestore: converter.toFirestore,
    );
  }
}
