import 'package:zema/zema.dart';

/// Thrown when a [ZemaBox] operation fails schema validation.
///
/// On write: thrown by [ZemaBox.put] / [ZemaBox.putAll] when the data does not
/// satisfy the schema, nothing is written to Hive.
///
/// On read: thrown internally and forwarded to [OnHiveParseError] when
/// [ZemaBox.get] cannot parse a stored document.
final class ZemaHiveException implements Exception {
  const ZemaHiveException(
    this.message, {
    this.key,
    this.issues,
    this.receivedData,
  });

  /// Human-readable description of the failure.
  final String message;

  /// Hive key of the document that failed validation, if applicable.
  final String? key;

  /// Validation issues reported by Zema.
  final List<ZemaIssue>? issues;

  /// Raw document data that failed validation, for debugging.
  final Map<String, dynamic>? receivedData;

  @override
  String toString() {
    final buffer = StringBuffer('ZemaHiveException: $message');

    if (key != null) buffer.write('\nKey: $key');

    if (issues != null && issues!.isNotEmpty) {
      buffer.write('\nValidation errors:');
      for (final issue in issues!) {
        final path = issue.path.isEmpty ? 'root' : issue.path.join('.');
        buffer.write('\n  $path [${issue.code}]: ${issue.message}');
      }
    }

    return buffer.toString();
  }
}
