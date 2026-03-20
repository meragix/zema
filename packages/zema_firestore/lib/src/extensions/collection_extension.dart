import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zema/zema.dart';

import '../core/firestore_converter.dart';

/// Adds [withZema] to [CollectionReference].
extension ZemaCollectionExtension on CollectionReference<Map<String, dynamic>> {
  /// Returns a typed [CollectionReference<T>] that parses and validates
  /// each document through [schema].
  ///
  /// ```dart
  /// final usersRef = FirebaseFirestore.instance
  ///     .collection('users')
  ///     .withZema<User>(userSchema);
  ///
  /// final snapshot = await usersRef.doc('123').get();
  /// final user = snapshot.data(); // User — already validated
  /// ```
  CollectionReference<T> withZema<T>(
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
