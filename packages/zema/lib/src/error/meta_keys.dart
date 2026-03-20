/// Compile-time constants for known [ZemaIssue.meta] interpolation keys.
///
/// Using these constants instead of raw string literals prevents typos that
/// would silently produce `null` values in translated messages.
///
/// ```dart
/// // Fragile — typo in 'min' key is invisible at compile time:
/// ZemaIssue(
///   code: 'too_short',
///   message: '...',
///   meta: {'minn': 2, 'actual': 1},   // silent typo
/// )
///
/// // Safe — typo caught at compile time:
/// ZemaIssue(
///   code: 'too_short',
///   message: '...',
///   meta: {ZemaMetaKeys.min: 2, ZemaMetaKeys.actual: 1},
/// )
/// ```
///
/// ## Built-in keys by error code
///
/// | Error code | Meta keys present |
/// |---|---|
/// | `invalid_type` | [expected], [received] |
/// | `too_short` | [min], [actual] |
/// | `too_long` | [max], [actual] |
/// | `wrong_length` | [length], [actual] |
/// | `too_small` | [min], [actual] |
/// | `too_big` | [max], [actual] |
/// | `too_small_exclusive` | [min], [actual] |
/// | `too_big_exclusive` | [max], [actual] |
/// | `invalid_enum` | [allowed] |
/// | `invalid_literal` | [expected], [received] |
/// | `invalid_coercion` | [type], [actual] |
/// | `not_multiple_of` | [multipleOf] |
/// | `date_too_early` | [min], [actual] |
/// | `date_too_late` | [max], [actual] |
/// | `invalid_format` | [pattern] |
abstract final class ZemaMetaKeys {
  /// The minimum allowed value or length. Used in `too_short`, `too_small`,
  /// `date_too_early`.
  static const String min = 'min';

  /// The maximum allowed value or length. Used in `too_long`, `too_big`,
  /// `date_too_late`.
  static const String max = 'max';

  /// The exact required length. Used in `wrong_length`.
  static const String length = 'length';

  /// The actual value received. Used in most constraint violations.
  static const String actual = 'actual';

  /// The expected type or value. Used in `invalid_type`, `invalid_literal`.
  static const String expected = 'expected';

  /// The received type name. Used in `invalid_type`.
  static const String received = 'received';

  /// The list of allowed values. Used in `invalid_enum`.
  static const String allowed = 'allowed';

  /// The target type name for coercion. Used in `invalid_coercion`.
  static const String type = 'type';

  /// The step value. Used in `not_multiple_of`.
  static const String multipleOf = 'multipleOf';

  /// The regex pattern. Used in `invalid_format`.
  static const String pattern = 'pattern';
}
