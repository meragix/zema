import 'package:zema/src/error/error_map.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// Formatted error structure (nested)
typedef ZemaFormattedErrors = Map<String, dynamic>;

/// Extension on List&lt;ZemaIssue&gt; for formatting
extension ZemaIssueListExtensions on List<ZemaIssue> {
  /// Format issues into nested structure
  /// 
  /// Example:
  /// ```dart
  /// {
  ///   "user": {
  ///     "email": {
  ///       "_errors": ["Invalid email format"]
  ///     },
  ///     "age": {
  ///       "_errors": ["Must be >= 18"]
  ///     }
  ///   }
  /// }
  /// ```
  ZemaFormattedErrors format() {
    final result = <String, dynamic>{};

    for (final issue in this) {
      _insertIssue(result, issue.path, issue.message);
    }

    return result;
  }

  /// Insert issue into nested structure
  void _insertIssue(
    Map<String, dynamic> target,
    List<Object> path,
    String message,
  ) {
    if (path.isEmpty) {
      // Root level error
      final errors = target['_errors'] as List<String>? ?? [];
      errors.add(message);
      target['_errors'] = errors;
      return;
    }

    var current = target;

    for (var i = 0; i < path.length; i++) {
      final segment = path[i];
      final isLast = i == path.length - 1;

      if (isLast) {
        // Last segment - add error
        final key = segment.toString();
        current[key] ??= <String, dynamic>{};
        final node = current[key] as Map<String, dynamic>;
        final errors = node['_errors'] as List<String>? ?? [];
        errors.add(message);
        node['_errors'] = errors;
      } else {
        // Intermediate segment - navigate or create
        final key = segment.toString();
        current[key] ??= <String, dynamic>{};
        current = current[key] as Map<String, dynamic>;
      }
    }
  }

  /// Get errors for a specific field path
  List<String>? errorsAt(List<Object> path) {
    final formatted = format();
    var current = formatted;

    for (final segment in path) {
      final next = current[segment.toString()];
      if (next == null) return null;
      if (next is! Map<String, dynamic>) return null;
      current = next;
    }

    return (current['_errors'] as List?)?.cast<String>();
  }

  /// Get first error for a specific field
  String? firstErrorAt(List<Object> path) => errorsAt(path)?.first;

  /// Check if a field has errors
  bool hasErrorsAt(List<Object> path) {
    final errors = errorsAt(path);
    return errors != null && errors.isNotEmpty;
  }

  /// Flatten all errors to a simple list of messages
  List<String> flatten() => map((issue) => issue.message).toList();

  /// Group errors by path
  Map<String, List<String>> groupByPath() {
    final result = <String, List<String>>{};

    for (final issue in this) {
      final path = issue.pathString;
      result[path] ??= [];
      result[path]!.add(issue.message);
    }

    return result;
  }

  /// Apply global error map to all issues
  List<ZemaIssue> applyErrorMap() {
    return map((issue) => ZemaErrorMap.applyErrorMap(issue)).toList();
  }

  /// Translate all issues using current locale
  List<ZemaIssue> translate() {
    return map((issue) {
      final translated = ZemaI18n.translate(issue.code, params: issue.meta);
      return issue.withMessage(translated);
    }).toList();
  }
}
