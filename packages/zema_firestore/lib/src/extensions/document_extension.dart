import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zema/zema.dart';

import '../core/firestore_converter.dart';

/// Adds [withZema] to [DocumentReference].
extension ZemaDocumentExtension on DocumentReference<Map<String, dynamic>> {
  /// Returns a typed [DocumentReference<T>] that parses and validates
  /// the document through [schema].
  ///
  /// ```dart
  /// final userRef = FirebaseFirestore.instance
  ///     .collection('users')
  ///     .doc('123')
  ///     .withZema<User>(userSchema);
  ///
  /// final snapshot = await userRef.get();
  /// final user = snapshot.data(); // User — already validated
  /// ```
  DocumentReference<T> withZema<T>(
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
