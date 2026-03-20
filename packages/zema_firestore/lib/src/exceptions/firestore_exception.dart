import 'package:zema/zema.dart';

/// Thrown when a Firestore document fails Zema schema validation,
/// or when a document does not exist and no fallback is provided.
final class ZemaFirestoreException implements Exception {
  const ZemaFirestoreException(
    this.message, {
    this.path,
    this.documentId,
    this.issues,
    this.receivedData,
  });

  /// Human-readable description of the failure.
  final String message;

  /// Firestore document path (e.g. `users/abc123`).
  final String? path;

  /// Firestore document ID.
  final String? documentId;

  /// Validation issues from the Zema schema, if the failure was a schema mismatch.
  final List<ZemaIssue>? issues;

  /// Raw document data at the time of failure, for debugging.
  final Map<String, dynamic>? receivedData;

  @override
  String toString() {
    final buf = StringBuffer('ZemaFirestoreException: $message');

    if (path != null) buf.write('\n  path: $path');
    if (documentId != null) buf.write('\n  id: $documentId');

    if (issues != null && issues!.isNotEmpty) {
      buf.write('\n  issues:');
      for (final issue in issues!) {
        final fieldPath = issue.path.isEmpty ? 'root' : issue.path.join('.');
        buf.write('\n    [$fieldPath] ${issue.code}: ${issue.message}');
      }
    }

    if (receivedData != null) buf.write('\n  data: $receivedData');

    return buf.toString();
  }
}
