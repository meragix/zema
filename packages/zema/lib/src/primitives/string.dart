import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/extensions/custom_message.dart';
import 'package:zema/src/helpers/validators.dart';

/// A schema that validates `String` values.
///
/// Construct via `z.string()` — do not instantiate directly.
///
/// ## Validation order
///
/// When multiple constraints are active, they are checked in this order:
/// 1. Type check — input must be a `String` (fail-fast, `invalid_type`).
/// 2. Trim — if [trim] was called, whitespace is stripped from both ends
///    **before** any further checks. The trimmed string is what gets returned
///    on success.
/// 3. Length — [min] and [max] are checked against the (possibly trimmed) length.
/// 4. Pattern — [regex] match is tested.
/// 5. Format — [email], [url], [uuid] are tested in that order.
/// 6. Enum — [oneOf] is checked last.
///
/// All active constraints are evaluated; every failure is collected and
/// returned together as a single [ZemaFailure].
///
/// ## Custom messages
///
/// Pass a `message` parameter to any constraint method to override the
/// default error message for that specific issue:
///
/// ```dart
/// z.string().min(8, message: 'Password must be at least 8 characters.')
/// z.string().email(message: 'Enter a valid email address.')
/// ```
///
/// ## Examples
///
/// ```dart
/// z.string()                     // any non-null string
/// z.string().min(2).max(50)      // between 2 and 50 chars
/// z.string().trim().min(1)       // non-blank (whitespace stripped first)
/// z.string().email()             // valid email address
/// z.string().url()               // valid URL
/// z.string().uuid()              // valid UUID v4
/// z.string().oneOf(['a', 'b'])   // must equal 'a' or 'b'
/// ```
///
/// See also:
/// - `z.coerce().string()` — converts any value to a string before validating.
final class ZemaString extends ZemaSchema<dynamic, String>
    with ZemaCustomMessage<dynamic, String> {
  /// Minimum allowed length (inclusive). `null` means no lower bound.
  final int? minLength;

  /// Maximum allowed length (inclusive). `null` means no upper bound.
  final int? maxLength;

  /// Custom regex the string must fully match. `null` means no pattern check.
  final RegExp? pattern;

  /// When `true`, input is trimmed with [String.trim] before all other checks.
  final bool shouldTrim;

  /// Closed set of allowed values. `null` means any value is accepted.
  final Set<String>? enumValues;

  /// When `true`, the string must be a valid email address.
  final bool? isEmail;

  /// When `true`, the string must be a valid URL.
  final bool? isUrl;

  /// When `true`, the string must be a valid UUID v4.
  final bool? isUuid;

  @override
  final String? customMessage;

  const ZemaString({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.shouldTrim = false,
    this.enumValues,
    this.isEmail,
    this.isUrl,
    this.isUuid,
    this.customMessage,
  });

  @override
  ZemaResult<String> safeParse(dynamic value) {
    // Type check
    if (value is! String) {
      final issue = ZemaIssue(
        code: 'invalid_type',
        message: ZemaI18n.translate(
          'invalid_type',
          params: {
            'expected': 'string',
            'received': value.runtimeType.toString(),
          },
        ),
        receivedValue: value,
        meta: {'expected': 'string', 'received': value.runtimeType.toString()},
      );
      return singleFailure(
        applyCustomMessage(issue),
      );
    }

    // Trim if requested
    final str = shouldTrim ? value.trim() : value;
    final issues = <ZemaIssue>[];

    // Length validation
    if (minLength != null && str.length < minLength!) {
      final issue = ZemaIssue(
        code: 'too_short',
        message: ZemaI18n.translate(
          'too_short',
          params: {
            'min': minLength,
            'actual': str.length,
          },
        ),
        receivedValue: str,
        meta: {'min': minLength, 'actual': str.length},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (maxLength != null && str.length > maxLength!) {
      final issue = ZemaIssue(
        code: 'too_long',
        message: ZemaI18n.translate(
          'too_long',
          params: {
            'max': maxLength,
            'actual': str.length,
          },
        ),
        receivedValue: str,
        meta: {'max': maxLength, 'actual': str.length},
      );
      issues.add(applyCustomMessage(issue));
    }

    // Pattern validation
    if (pattern != null && !pattern!.hasMatch(str)) {
      issues.add(
        ZemaIssue(
          code: 'invalid_format',
          message: 'String does not match required pattern',
          meta: {'pattern': pattern!.pattern},
        ),
      );
    }

    // Email validation
    if (isEmail == true && !Validators.emailRegex.hasMatch(str)) {
      final issue = ZemaIssue(
        code: 'invalid_email',
        message: ZemaI18n.translate('invalid_email'),
        receivedValue: str,
      );
      issues.add(applyCustomMessage(issue));
    }

    // URL validation
    if (isUrl == true && !Validators.urlRegex.hasMatch(str)) {
      issues.add(
        ZemaIssue(
          code: 'invalid_url',
          message: ZemaI18n.translate('invalid_url'),
          receivedValue: str,
        ),
      );
    }

    // UUID validation
    if (isUuid == true && !Validators.uuidRegex.hasMatch(str)) {
      issues.add(
        ZemaIssue(
          code: 'invalid_uuid',
          message: ZemaI18n.translate('invalid_uuid'),
          receivedValue: str,
        ),
      );
    }

    // Enum validation
    if (enumValues != null && !enumValues!.contains(str)) {
      final issue = ZemaIssue(
        code: 'invalid_enum',
        message: ZemaI18n.translate(
          'invalid_enum',
          params: {
            'allowed': enumValues!.toList(),
          },
        ),
        receivedValue: str,
        meta: {'allowed': enumValues!.toList()},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(str);
  }

  // ===========================================================================
  // Fluent API
  // ===========================================================================

  /// Strips leading and trailing whitespace from the input **before** any
  /// other checks are applied.
  ///
  /// The trimmed string is what gets returned on success. Call [trim] before
  /// [min] to enforce a non-blank constraint:
  ///
  /// ```dart
  /// z.string().trim().min(1)  // '  ' fails (trimmed to '' → length 0)
  /// z.string().min(1)         // '  ' passes (raw length 2 >= 1)
  /// ```
  ZemaString trim() => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: true,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: isUuid,
      );

  /// Requires the string to have at least [length] characters.
  ///
  /// The check is applied **after** trimming if [trim] was called.
  /// Produces a `too_short` issue on failure.
  ///
  /// ```dart
  /// z.string().min(2)                          // default message
  /// z.string().min(8, message: 'Too short.')   // custom message
  /// ```
  ZemaString min(int length, {String? message}) => ZemaString(
        minLength: length,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: isUuid,
      );

  /// Requires the string to have at most [length] characters.
  ///
  /// The check is applied **after** trimming if [trim] was called.
  /// Produces a `too_long` issue on failure.
  ///
  /// ```dart
  /// z.string().max(100)
  /// z.string().max(280, message: 'Tweet cannot exceed 280 characters.')
  /// ```
  ZemaString max(int length, {String? message}) => ZemaString(
        minLength: minLength,
        maxLength: length,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: isUuid,
      );

  /// Requires the string to be a syntactically valid email address.
  ///
  /// Validation uses an RFC-aligned regex. Does not perform DNS resolution.
  /// Produces an `invalid_email` issue on failure.
  ///
  /// ```dart
  /// z.string().email()
  /// z.string().email(message: 'Please enter a valid email.')
  /// ```
  ZemaString email({String? message}) => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: true,
        isUrl: isUrl,
        isUuid: isUuid,
      );

  /// Requires the string to be a syntactically valid URL.
  ///
  /// Both `http` and `https` schemes are accepted. Produces an `invalid_url`
  /// issue on failure.
  ///
  /// ```dart
  /// z.string().url()
  /// ```
  ZemaString url() => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: true,
        isUuid: isUuid,
      );

  /// Requires the string to be a valid UUID (version 4 format).
  ///
  /// Matching is case-insensitive. Produces an `invalid_uuid` issue on failure.
  ///
  /// ```dart
  /// z.string().uuid()
  ///
  /// // example valid value
  /// z.string().uuid().parse('550e8400-e29b-41d4-a716-446655440000');
  /// ```
  ZemaString uuid() => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: true,
      );

  /// Requires the string to be one of the provided [values].
  ///
  /// Comparison is exact (`==`). Produces an `invalid_enum` issue on failure,
  /// with `meta['allowed']` containing the full list of valid values.
  ///
  /// ```dart
  /// z.string().oneOf(['admin', 'editor', 'viewer'])
  /// ```
  ///
  /// See also:
  /// - `z.literal(value)` — for a schema that matches a single exact value.
  ZemaString oneOf(List<String> values) => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: values.toSet(),
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: isUuid,
      );
}
