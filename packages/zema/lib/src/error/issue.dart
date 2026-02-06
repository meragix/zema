import 'package:meta/meta.dart';

/// Immutable validation issue with full context
@immutable
final class ZemaIssue {
  /// Error code for programmatic handling (e.g., 'invalid_string', 'too_short')
  final String code;

  /// Human-readable error message
  final String message;

  /// Path to the field that failed (e.g., ['user', 'email'] or ['items', 0, 'name'])
  final List<Object> path;

  /// The value that failed validation (for debugging)
  final Object? receivedValue;

  /// Additional metadata
  final Map<String, dynamic>? meta;

  const ZemaIssue({
    required this.code,
    required this.message,
    this.path = const [],
    this.receivedValue,
    this.meta,
  });

  /// Create a new issue with an additional path segment
  ZemaIssue withPath(Object segment) => ZemaIssue(
        code: code,
        message: message,
        path: [...path, segment],
        receivedValue: receivedValue,
        meta: meta,
      );

  /// Create a new issue with prepended path segments
  ZemaIssue prependPath(List<Object> segments) => ZemaIssue(
        code: code,
        message: message,
        path: [...segments, ...path],
        receivedValue: receivedValue,
        meta: meta,
      );

  /// Create a copy with custom message
  ZemaIssue withMessage(String newMessage) => ZemaIssue(
        code: code,
        message: newMessage,
        path: path,
        receivedValue: receivedValue,
        meta: meta,
      );

  /// Format path as human-readable string
  String get pathString => path.isEmpty
      ? 'root'
      : path.map((p) => p is int ? '[$p]' : p.toString()).join('.');

  @override
  String toString() {
    final pathStr = path.isEmpty ? '' : ' at $pathString';
    final valueStr = receivedValue != null ? ' (received: $receivedValue)' : '';
    return '[$code]$pathStr: $message$valueStr';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZemaIssue &&
          code == other.code &&
          message == other.message &&
          _listEquals(path, other.path) &&
          receivedValue == other.receivedValue;

  @override
  int get hashCode => Object.hash(
        code,
        message,
        Object.hashAll(path),
        receivedValue,
      );

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}