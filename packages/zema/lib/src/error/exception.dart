import 'package:zema/src/error/issue.dart';

/// Exception thrown by parse() when validation fails
final class ZemaException implements Exception {
  final List<ZemaIssue> issues;

  const ZemaException(this.issues);

  @override
  String toString() {
    if (issues.isEmpty) return 'ZemaException: Unknown validation error';
    if (issues.length == 1) return 'ZemaException: ${issues.first}';
    return 'ZemaException: Multiple validation errors:\n${issues.map((i) => '  - $i').join('\n')}';
  }
}
