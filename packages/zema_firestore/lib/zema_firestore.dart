/// Zema schema validation integration for Cloud Firestore.
///
/// Hooks into Firestore's native [withConverter] API so every document read
/// is automatically validated against a Zema schema.
///
/// ## Setup
///
/// ```dart
/// import 'package:zema/zema.dart';
/// import 'package:zema_firestore/zema_firestore.dart';
///
/// final userSchema = z.object({
///   'id': z.string(),
///   'name': z.string().min(1),
///   'email': z.string().email(),
///   'createdAt': zTimestamp(),
/// });
///
/// final usersRef = FirebaseFirestore.instance
///     .collection('users')
///     .withZema(userSchema);
///
/// // Reading
/// final snapshot = await usersRef.doc('abc').get();
/// final user = snapshot.data(); // Map<String, dynamic> — validated
///
/// // Writing
/// await usersRef.doc('abc').set({'name': 'Alice', 'email': 'alice@example.com'});
/// ```
library;

// Firebase type schemas
export 'src/types/firebase_types.dart';

// Converter
export 'src/core/firestore_converter.dart'
    show ZemaFirestoreConverter, OnParseError;

// Exception
export 'src/exceptions/firestore_exception.dart';

// Extensions
export 'src/extensions/collection_extension.dart';
export 'src/extensions/document_extension.dart';
export 'src/extensions/query_extension.dart';
