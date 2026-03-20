import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zema/zema.dart';

/// Schema that accepts a Firestore [Timestamp] or a [DateTime] and
/// transforms the value to [DateTime].
///
/// Use this for Firestore timestamp fields so the validated output is always
/// a Dart [DateTime], regardless of whether the raw value came from Firestore
/// (as a [Timestamp]) or from in-memory app code (as a [DateTime]).
///
/// ```dart
/// final schema = z.object({
///   'createdAt': zTimestamp(),
/// });
/// ```
ZemaSchema<dynamic, DateTime> zTimestamp() {
  return z
      .custom<dynamic>(
    (value) => value is Timestamp || value is DateTime,
    message: 'Expected Timestamp or DateTime',
  )
      .transform((value) {
    if (value is Timestamp) return value.toDate();
    return value as DateTime;
  });
}

/// Schema that validates a Firestore [GeoPoint].
///
/// ```dart
/// final schema = z.object({
///   'location': zGeoPoint(),
/// });
/// ```
ZemaSchema<dynamic, GeoPoint> zGeoPoint() {
  return z
      .custom<dynamic>(
        (value) => value is GeoPoint,
        message: 'Expected GeoPoint',
      )
      .transform((value) => value as GeoPoint);
}

/// Schema that validates a Firestore [DocumentReference].
///
/// ```dart
/// final schema = z.object({
///   'authorRef': zDocumentRef(),
/// });
/// ```
ZemaSchema<dynamic, DocumentReference<Map<String, dynamic>>> zDocumentRef() {
  return z
      .custom<dynamic>(
        (value) => value is DocumentReference,
        message: 'Expected DocumentReference',
      )
      .transform(
        (value) => value as DocumentReference<Map<String, dynamic>>,
      );
}

/// Schema that validates a Firestore [Blob].
///
/// ```dart
/// final schema = z.object({
///   'avatar': zBlob(),
/// });
/// ```
ZemaSchema<dynamic, Blob> zBlob() {
  return z
      .custom<dynamic>(
        (value) => value is Blob,
        message: 'Expected Blob',
      )
      .transform((value) => value as Blob);
}
