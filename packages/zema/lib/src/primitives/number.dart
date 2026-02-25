import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/extensions/custom_message.dart';

/// A schema that validates Dart `int` values.
///
/// Construct via `z.int()` — do not instantiate directly.
///
/// Only accepts Dart `int`s. `double` values (even whole-number ones like
/// `42.0`) and numeric strings are rejected with an `invalid_type` issue.
/// Use `z.coerce().integer()` when the input may be a string or double.
///
/// ## Constraints
///
/// All active constraints are evaluated after the type check; all failures
/// are returned together as a single [ZemaFailure]:
///
/// | Method | Condition | Issue code |
/// |---|---|---|
/// | [gte] | value >= min | `too_small` |
/// | [lte] | value <= max | `too_big` |
/// | [positive] | value > 0 | `not_positive` |
/// | [negative] | value < 0 | `not_negative` |
/// | [step] | value % n == 0 | `not_multiple_of` |
///
/// ## Examples
///
/// ```dart
/// z.int()                          // any integer
/// z.int().gte(0)                   // >= 0
/// z.int().lte(100)                 // <= 100
/// z.int().gte(1).lte(5)            // 1..5 inclusive
/// z.int().positive()               // > 0
/// z.int().negative()               // < 0
/// z.int().step(5)                  // 0, 5, 10, 15, …
/// z.int().positive().step(2)       // positive even numbers
/// ```
///
/// See also:
/// - [ZemaDouble] — for `double` values.
/// - `z.coerce().integer()` — coerces strings/doubles to `int` first.
final class ZemaInt extends ZemaSchema<dynamic, int>
    with ZemaCustomMessage<dynamic, int> {
  /// Lower bound (inclusive). `null` means no lower limit.
  final int? min;

  /// Upper bound (inclusive). `null` means no upper limit.
  final int? max;

  /// When `true`, value must be strictly greater than zero.
  final bool? isPositive;

  /// When `true`, value must be strictly less than zero.
  final bool? isNegative;

  /// When set, value must be evenly divisible by this number.
  final int? multipleOf;

  @override
  final String? customMessage;

  const ZemaInt({
    this.min,
    this.max,
    this.isPositive,
    this.isNegative,
    this.multipleOf,
    this.customMessage,
  });

  @override
  ZemaResult<int> safeParse(dynamic value) {
    if (value is! int) {
      final issue = ZemaIssue(
        code: 'invalid_type',
        message: ZemaI18n.translate(
          'invalid_type',
          params: {
            'expected': 'int',
            'received': value.runtimeType.toString(),
          },
        ),
        receivedValue: value,
        meta: {'expected': 'int', 'received': value.runtimeType.toString()},
      );
      return singleFailure(applyCustomMessage(issue));
    }

    final issues = <ZemaIssue>[];

    if (min != null && value < min!) {
      final issue = ZemaIssue(
        code: 'too_small',
        message: ZemaI18n.translate(
          'too_small',
          params: {
            'min': min,
            'actual': value,
          },
        ),
        receivedValue: value,
        meta: {'min': min, 'actual': value},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (max != null && value > max!) {
      final issue = ZemaIssue(
        code: 'too_big',
        message: ZemaI18n.translate(
          'too_big',
          params: {
            'max': max,
            'actual': value,
          },
        ),
        receivedValue: value,
        meta: {'max': max, 'actual': value},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (isPositive == true && value <= 0) {
      final issue = ZemaIssue(
        code: 'not_positive',
        message: ZemaI18n.translate('not_positive'),
        receivedValue: value,
        meta: {
          'expected': 'positive integer',
          'received': value,
        },
      );
      issues.add(applyCustomMessage(issue));
    }

    if (isNegative == true && value >= 0) {
      final issue = ZemaIssue(
        code: 'not_negative',
        message: ZemaI18n.translate('not_negative'),
        receivedValue: value,
        meta: {
          'expected': 'negative integer',
          'received': value,
        },
      );
      issues.add(applyCustomMessage(issue));
    }

    if (multipleOf != null && value % multipleOf! != 0) {
      final issue = ZemaIssue(
        code: 'not_multiple_of',
        message: ZemaI18n.translate(
          'not_multiple_of',
          params: {'multipleOf': multipleOf},
        ),
        receivedValue: value,
        meta: {
          'expected': 'multiple of $multipleOf',
          'received': value,
        },
      );
      issues.add(applyCustomMessage(issue));
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(value);
  }

  // ===========================================================================
  // Fluent API
  // ===========================================================================

  /// Requires the value to be greater than or equal to [value].
  ///
  /// Produces a `too_small` issue on failure.
  ///
  /// ```dart
  /// z.int().gte(0)                          // non-negative
  /// z.int().gte(1, message: 'Must be >= 1')
  /// ```
  ZemaInt gte(int value, {String? message}) => ZemaInt(
        min: value,
        max: max,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: multipleOf,
        customMessage: message,
      );

  /// Requires the value to be less than or equal to [value].
  ///
  /// Produces a `too_big` issue on failure.
  ///
  /// ```dart
  /// z.int().lte(100)
  /// z.int().gte(0).lte(255)   // byte range
  /// ```
  ZemaInt lte(int value, {String? message}) => ZemaInt(
        min: min,
        max: value,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: multipleOf,
        customMessage: message,
      );

  /// Requires the value to be strictly greater than zero (`value > 0`).
  ///
  /// Produces a `not_positive` issue on failure. Note that `0` is **not**
  /// positive — use [gte]`(0)` if you want to include zero.
  ///
  /// ```dart
  /// z.int().positive()
  /// z.int().positive(message: 'Quantity must be positive.')
  /// ```
  ZemaInt positive({String? message}) => ZemaInt(
        min: min,
        max: max,
        isPositive: true,
        isNegative: isNegative,
        multipleOf: multipleOf,
        customMessage: message,
      );

  /// Requires the value to be strictly less than zero (`value < 0`).
  ///
  /// Produces a `not_negative` issue on failure. Note that `0` is **not**
  /// negative — use [lte]`(-1)` if you need to exclude zero explicitly.
  ///
  /// ```dart
  /// z.int().negative()
  /// ```
  ZemaInt negative({String? message}) => ZemaInt(
        min: min,
        max: max,
        isPositive: isPositive,
        isNegative: true,
        multipleOf: multipleOf,
        customMessage: message,
      );

  /// Requires the value to be a multiple of [value] (`value % n == 0`).
  ///
  /// Produces a `not_multiple_of` issue on failure.
  ///
  /// ```dart
  /// z.int().step(5)    // 0, 5, 10, 15, …
  /// z.int().step(2)    // even numbers
  /// ```
  ZemaInt step(int value, {String? message}) => ZemaInt(
        min: min,
        max: max,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: value,
        customMessage: message,
      );
}

/// A schema that validates Dart `double` values.
///
/// Construct via `z.double()` — do not instantiate directly.
///
/// Only accepts Dart `double`s. `int` values and numeric strings are rejected
/// with an `invalid_type` issue. Use `z.coerce().float()` when the input may
/// be an integer or string.
///
/// ## Constraints
///
/// All active constraints are evaluated after the type check. The finiteness
/// check runs first among constraints so that `NaN` and `Infinity` don't
/// produce misleading range errors:
///
/// | Method | Condition | Issue code |
/// |---|---|---|
/// | [finite] | !value.isNaN && !value.isInfinite | `not_finite` |
/// | [gte] | value >= min | `too_small` |
/// | [lte] | value <= max | `too_big` |
/// | [positive] | value > 0.0 | `not_positive` |
///
/// ## Examples
///
/// ```dart
/// z.double()                  // any double
/// z.double().gte(0.0)         // non-negative
/// z.double().gte(0.0).lte(1.0) // probability range [0, 1]
/// z.double().positive()       // > 0.0
/// z.double().finite()         // rejects NaN, Infinity, -Infinity
/// z.double().finite().gte(0.0)
/// ```
///
/// See also:
/// - [ZemaInt] — for integer values.
/// - `z.coerce().float()` — coerces strings/ints to `double` first.
final class ZemaDouble extends ZemaSchema<dynamic, double>
    with ZemaCustomMessage<dynamic, double> {
  /// Lower bound (inclusive). `null` means no lower limit.
  final double? min;

  /// Upper bound (inclusive). `null` means no upper limit.
  final double? max;

  /// When `true`, value must be strictly greater than zero.
  final bool? isPositive;

  /// When `true`, value must be strictly less than zero.
  final bool? isNegative;

  /// When `true`, value must not be `NaN`, `Infinity`, or `-Infinity`.
  final bool? isFinite;

  @override
  final String? customMessage;

  const ZemaDouble({
    this.min,
    this.max,
    this.isPositive,
    this.isNegative,
    this.isFinite,
    this.customMessage,
  });

  @override
  ZemaResult<double> safeParse(dynamic value) {
    if (value is! double) {
      final issue = ZemaIssue(
        code: 'invalid_type',
        message: ZemaI18n.translate(
          'invalid_type',
          params: {
            'expected': 'double',
            'received': value.runtimeType.toString(),
          },
        ),
        receivedValue: value,
        meta: {'expected': 'double', 'received': value.runtimeType.toString()},
      );
      return singleFailure(applyCustomMessage(issue));
    }

    final issues = <ZemaIssue>[];

    if (isFinite == true && !value.isFinite) {
      issues.add(
        ZemaIssue(
          code: 'not_finite',
          message: ZemaI18n.translate('not_finite'),
          receivedValue: value,
          meta: {'received': value},
        ),
      );
    }

    if (min != null && value < min!) {
      final issue = ZemaIssue(
        code: 'too_small',
        message: ZemaI18n.translate(
          'too_small',
          params: {
            'min': min,
            'actual': value,
          },
        ),
        receivedValue: value,
        meta: {'min': min, 'actual': value},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (max != null && value > max!) {
      final issue = ZemaIssue(
        code: 'too_big',
        message: ZemaI18n.translate(
          'too_big',
          params: {
            'max': max,
            'actual': value,
          },
        ),
        receivedValue: value,
        meta: {'max': max, 'actual': value},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (isPositive == true && value <= 0) {
      final issue = ZemaIssue(
        code: 'not_positive',
        message: ZemaI18n.translate('not_positive'),
        receivedValue: value,
        meta: {
          'expected': 'positive double',
          'received': value,
        },
      );
      issues.add(applyCustomMessage(issue));
    }

    if (isNegative == true && value >= 0) {
      final issue = ZemaIssue(
        code: 'not_negative',
        message: ZemaI18n.translate('not_negative'),
        receivedValue: value,
        meta: {
          'expected': 'negative double',
          'received': value,
        },
      );
      issues.add(applyCustomMessage(issue));
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(value);
  }

  // ===========================================================================
  // Fluent API
  // ===========================================================================

  /// Requires the value to be greater than or equal to [value].
  ///
  /// Produces a `too_small` issue on failure.
  ///
  /// ```dart
  /// z.double().gte(0.0)              // non-negative
  /// z.double().gte(0.0, message: 'Must be >= 0.')
  /// ```
  ZemaDouble gte(double value, {String? message}) => ZemaDouble(
        min: value,
        max: max,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: isFinite,
        customMessage: message,
      );

  /// Requires the value to be less than or equal to [value].
  ///
  /// Produces a `too_big` issue on failure.
  ///
  /// ```dart
  /// z.double().lte(1.0)
  /// z.double().gte(0.0).lte(1.0)   // probability: [0.0, 1.0]
  /// ```
  ZemaDouble lte(double value, {String? message}) => ZemaDouble(
        min: min,
        max: value,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: isFinite,
        customMessage: message,
      );

  /// Requires the value to be strictly greater than zero (`value > 0.0`).
  ///
  /// Produces a `not_positive` issue on failure. Note that `0.0` is **not**
  /// positive — use [gte]`(0.0)` if you want to include zero.
  ///
  /// ```dart
  /// z.double().positive()
  /// ```
  ZemaDouble positive() => ZemaDouble(
        min: min,
        max: max,
        isPositive: true,
        isNegative: isNegative,
        isFinite: isFinite,
      );

  /// Requires the value to be a finite number — not `NaN`, `Infinity`, or
  /// `-Infinity`.
  ///
  /// Produces a `not_finite` issue on failure. Chain with range constraints
  /// to combine finiteness and bounds checks:
  ///
  /// ```dart
  /// z.double().finite()
  /// z.double().finite().gte(0.0)   // finite and non-negative
  /// ```
  ZemaDouble finite() => ZemaDouble(
        min: min,
        max: max,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: true,
      );
}
