import 'package:meta/meta.dart';
import 'package:zema/src/error/severity.dart';

/// An immutable, self-describing validation failure.
///
/// Every time a schema rejects a value it produces one or more [ZemaIssue]s.
/// An issue carries five pieces of information:
///
/// - **[code]** — a stable string identifier for programmatic handling.
/// - **[message]** — a human-readable description, localised via [ZemaI18n].
/// - **[path]** — the location in the input structure where the failure
///   occurred (empty for root-level failures).
/// - **[receivedValue]** / **[expected]** / **[meta]** — additional context
///   for debugging and error-map customisation.
/// - **[severity]** — whether the issue is a hard [ZemaSeverity.error] that
///   blocks the parse, or an informational [ZemaSeverity.warning] that lets
///   the parse succeed (see [ZemaSchemaRefinement.refineWarn]).
///
/// ## Path format
///
/// [path] is a list of `String` (field names) and `int` (array indices)
/// segments that, read left to right, locate the failed field:
///
/// ```
/// path: []                  → pathString: 'root'
/// path: ['email']           → pathString: 'email'
/// path: ['items', 2, 'name']→ pathString: 'items.[2].name'
/// ```
///
/// Parent schemas (e.g. [ZemaObject], [ZemaArray]) prepend their own segment
/// to child issues via [withPath], so the final path is fully qualified
/// without any extra work from the leaf schema.
///
/// ## toString format
///
/// ```
/// [invalid_email] at user.email: Invalid email format (received: notAnEmail)
/// [weak_password] [WARNING]: Adding uppercase letters improves password strength.
/// ```
@immutable
final class ZemaIssue {
  /// Stable string identifier for this kind of failure.
  ///
  /// Use [code] in your application logic to distinguish issue types without
  /// depending on the human-readable [message], which may be translated or
  /// overridden. See the class documentation for the full list of built-in
  /// codes.
  final String code;

  /// Human-readable description of the failure.
  ///
  /// The default message is produced by [ZemaI18n] using the active locale.
  /// It can be overridden globally via [ZemaErrorMap.setErrorMap] or
  /// per-schema via the `message` parameter on individual constraint methods
  /// (e.g. `z.string().min(2, message: 'Too short.')`).
  final String message;

  /// Location in the input structure where the failure occurred.
  ///
  /// Empty (`[]`) for root-level failures. Each element is either a `String`
  /// (object key) or an `int` (array/list index). Schemas that wrap others
  /// prepend their own segment via [withPath].
  ///
  /// See [pathString] for a formatted, human-readable representation.
  final List<Object> path;

  /// The raw value that failed validation, included for debugging purposes.
  ///
  /// May be `null` when the failing schema does not capture the received value
  /// (e.g. type-level failures in some schemas).
  final Object? receivedValue;

  /// The expected type or value, for `invalid_type` and similar issues.
  ///
  /// Complements [receivedValue] — together they let you produce messages like
  /// `"Expected int, got String"` without depending on the freeform [message].
  ///
  /// ```dart
  /// ZemaIssue(
  ///   code: 'invalid_type',
  ///   message: 'Expected int',
  ///   expected: 'int',
  ///   receivedValue: 'hello',
  /// )
  /// ```
  final String? expected;

  /// Arbitrary key-value metadata attached to this issue.
  ///
  /// Used by [ZemaI18n] to interpolate dynamic values into translated messages
  /// (e.g. `{'min': 2, 'actual': 1}` for a `too_short` issue) and available
  /// to [ZemaErrorMap] functions for custom message generation.
  ///
  /// Prefer [ZemaMetaKeys] constants for map keys to avoid silent typos:
  ///
  /// ```dart
  /// meta: {ZemaMetaKeys.min: 2, ZemaMetaKeys.actual: 1}
  /// ```
  final Map<String, dynamic>? meta;

  /// Whether this issue is a hard error or an informational warning.
  ///
  /// - [ZemaSeverity.error] (default) — parse fails; result is [ZemaFailure].
  /// - [ZemaSeverity.warning] — parse succeeds; issue is surfaced via
  ///   [ZemaResult.warnings] instead of [ZemaResult.errors].
  ///
  /// Warning-level issues are produced by [ZemaSchemaRefinement.refineWarn].
  final ZemaSeverity severity;

  const ZemaIssue({
    required this.code,
    required this.message,
    this.path = const [],
    this.receivedValue,
    this.expected,
    this.meta,
    this.severity = ZemaSeverity.error,
  });

  // ===========================================================================
  // Copy helpers
  // ===========================================================================

  /// Returns a copy of this issue with [segment] appended to the end of [path].
  ///
  /// Used internally by container schemas ([ZemaObject], [ZemaArray]) to
  /// prefix child issues with the parent's key or index:
  ///
  /// ```dart
  /// // object schema for key 'email'
  /// childIssue.withPath('email');
  /// // → path: [...childIssue.path, 'email']
  ///
  /// // array schema for index 2
  /// childIssue.withPath(2);
  /// // → path: [...childIssue.path, 2]
  /// ```
  ZemaIssue withPath(Object segment) => ZemaIssue(
        code: code,
        message: message,
        path: [...path, segment],
        receivedValue: receivedValue,
        expected: expected,
        meta: meta,
        severity: severity,
      );

  /// Returns a copy of this issue with [segments] prepended to the front of
  /// [path].
  ///
  /// Useful when re-nesting issues from a nested schema into a parent context:
  ///
  /// ```dart
  /// issue.prependPath(['user', 'address']);
  /// // → path: ['user', 'address', ...issue.path]
  /// ```
  ZemaIssue prependPath(List<Object> segments) => ZemaIssue(
        code: code,
        message: message,
        path: [...segments, ...path],
        receivedValue: receivedValue,
        expected: expected,
        meta: meta,
        severity: severity,
      );

  /// Returns a copy of this issue with [message] replaced by [newMessage].
  ///
  /// Used by [ZemaErrorMap.applyErrorMap] and the [ZemaCustomMessage] mixin
  /// to substitute custom messages without changing any other field.
  ZemaIssue withMessage(String newMessage) => ZemaIssue(
        code: code,
        message: newMessage,
        path: path,
        receivedValue: receivedValue,
        expected: expected,
        meta: meta,
        severity: severity,
      );

  // ===========================================================================
  // Formatting
  // ===========================================================================

  /// A human-readable representation of [path].
  ///
  /// - Empty path → `'root'`
  /// - String segments → joined with `.`
  /// - Integer segments → wrapped in `[…]`
  ///
  /// ```
  /// []                    → 'root'
  /// ['email']             → 'email'
  /// ['items', 2, 'name']  → 'items.[2].name'
  /// ```
  String get pathString => path.isEmpty
      ? 'root'
      : path.map((p) => p is int ? '[$p]' : p.toString()).join('.');

  @override
  String toString() {
    final pathStr = path.isEmpty ? '' : ' at $pathString';
    final valueStr = receivedValue != null ? ' (received: $receivedValue)' : '';
    final expectedStr = expected != null ? ' (expected: $expected)' : '';
    final severityStr = severity == ZemaSeverity.warning ? ' [WARNING]' : '';
    return '[$code]$pathStr$severityStr: $message$valueStr$expectedStr';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZemaIssue &&
          code == other.code &&
          message == other.message &&
          _listEquals(path, other.path) &&
          receivedValue == other.receivedValue &&
          expected == other.expected &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(
        code,
        message,
        Object.hashAll(path),
        receivedValue,
        expected,
        severity,
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
