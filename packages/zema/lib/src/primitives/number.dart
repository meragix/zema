import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/extensions/custom_message.dart';

/// A schema that validates Dart `int` values.
///
/// Construct via `z.integer()` — do not instantiate directly.
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
/// | [nonNegative] | value >= 0 | `too_small` |
/// | [step] | value % n == 0 | `not_multiple_of` |
///
/// ## Examples
///
/// ```dart
/// z.integer()                          // any integer
/// z.integer().gte(0)                   // >= 0
/// z.integer().lte(100)                 // <= 100
/// z.integer().gte(1).lte(5)            // 1..5 inclusive
/// z.integer().positive()               // > 0
/// z.integer().negative()               // < 0
/// z.integer().step(5)                  // 0, 5, 10, 15, …
/// z.integer().positive().step(2)       // positive even numbers
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

  /// Exclusive lower bound. `null` means no exclusive lower limit.
  final int? exclusiveMin;

  /// Exclusive upper bound. `null` means no exclusive upper limit.
  final int? exclusiveMax;

  @override
  final String? customMessage;

  const ZemaInt({
    this.min,
    this.max,
    this.isPositive,
    this.isNegative,
    this.multipleOf,
    this.exclusiveMin,
    this.exclusiveMax,
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

    List<ZemaIssue>? issues;

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
      (issues ??= []).add(applyCustomMessage(issue));
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
      (issues ??= []).add(applyCustomMessage(issue));
    }

    if (exclusiveMin != null && value <= exclusiveMin!) {
      final issue = ZemaIssue(
        code: 'too_small_exclusive',
        message: ZemaI18n.translate(
          'too_small_exclusive',
          params: {'min': exclusiveMin, 'actual': value},
        ),
        receivedValue: value,
        meta: {'min': exclusiveMin, 'actual': value},
      );
      (issues ??= []).add(applyCustomMessage(issue));
    }

    if (exclusiveMax != null && value >= exclusiveMax!) {
      final issue = ZemaIssue(
        code: 'too_big_exclusive',
        message: ZemaI18n.translate(
          'too_big_exclusive',
          params: {'max': exclusiveMax, 'actual': value},
        ),
        receivedValue: value,
        meta: {'max': exclusiveMax, 'actual': value},
      );
      (issues ??= []).add(applyCustomMessage(issue));
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
      (issues ??= []).add(applyCustomMessage(issue));
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
      (issues ??= []).add(applyCustomMessage(issue));
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
      (issues ??= []).add(applyCustomMessage(issue));
    }

    if (issues != null) return failure(issues);
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
  /// z.integer().gte(0) // non-negative
  /// z.integer().gte(1, message: 'Must be >= 1')
  /// ```
  ZemaInt gte(int value, {String? message}) => ZemaInt(
        min: value,
        max: max,
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
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
  /// z.integer().lte(100)
  /// z.integer().gte(0).lte(255)   // byte range
  /// ```
  ZemaInt lte(int value, {String? message}) => ZemaInt(
        min: min,
        max: value,
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
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
  /// z.integer().positive()
  /// z.integer().positive(message: 'Quantity must be positive.')
  /// ```
  ZemaInt positive({String? message}) => ZemaInt(
        min: min,
        max: max,
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
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
  /// z.integer().negative()
  /// ```
  ZemaInt negative({String? message}) => ZemaInt(
        min: min,
        max: max,
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
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
  /// z.integer().step(5)    // 0, 5, 10, 15, …
  /// z.integer().step(2)    // even numbers
  /// ```
  ZemaInt step(int value, {String? message}) => ZemaInt(
        min: min,
        max: max,
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: value,
        customMessage: message,
      );

  /// Requires the value to be strictly greater than [value] (`value > n`).
  ///
  /// Produces a `too_small_exclusive` issue on failure. Differs from [gte]
  /// in that the bound itself is not valid.
  ///
  /// ```dart
  /// z.integer().gt(0)   // 1, 2, 3, … (0 is rejected)
  /// z.integer().gt(18)  // strictly older than 18
  /// ```
  ZemaInt gt(int value, {String? message}) => ZemaInt(
        min: min,
        max: max,
        exclusiveMin: value,
        exclusiveMax: exclusiveMax,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: multipleOf,
        customMessage: message,
      );

  /// Requires the value to be strictly less than [value] (`value < n`).
  ///
  /// Produces a `too_big_exclusive` issue on failure. Differs from [lte]
  /// in that the bound itself is not valid.
  ///
  /// ```dart
  /// z.integer().lt(100)   // …, 97, 98, 99 (100 is rejected)
  /// z.integer().lt(0)     // strictly negative
  /// ```
  ZemaInt lt(int value, {String? message}) => ZemaInt(
        min: min,
        max: max,
        exclusiveMin: exclusiveMin,
        exclusiveMax: value,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: multipleOf,
        customMessage: message,
      );

  /// Requires the value to be greater than or equal to zero (`value >= 0`).
  ///
  /// Produces a `too_small` issue on failure. Equivalent to [gte]`(0)`.
  ///
  /// ```dart
  /// z.integer().nonNegative()
  /// z.integer().nonNegative(message: 'Stock cannot be negative.')
  /// ```
  ZemaInt nonNegative({String? message}) => ZemaInt(
        min: 0,
        max: max,
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: multipleOf,
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
/// | [nonNegative] | value >= 0.0 | `too_small` |
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

  /// Exclusive lower bound. `null` means no exclusive lower limit.
  final double? exclusiveMin;

  /// Exclusive upper bound. `null` means no exclusive upper limit.
  final double? exclusiveMax;

  @override
  final String? customMessage;

  const ZemaDouble({
    this.min,
    this.max,
    this.isPositive,
    this.isNegative,
    this.isFinite,
    this.exclusiveMin,
    this.exclusiveMax,
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

    List<ZemaIssue>? issues;

    if (isFinite == true && !value.isFinite) {
      (issues ??= []).add(
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
      (issues ??= []).add(applyCustomMessage(issue));
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
      (issues ??= []).add(applyCustomMessage(issue));
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
      (issues ??= []).add(applyCustomMessage(issue));
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
      (issues ??= []).add(applyCustomMessage(issue));
    }

    if (exclusiveMin != null && value <= exclusiveMin!) {
      final issue = ZemaIssue(
        code: 'too_small_exclusive',
        message: ZemaI18n.translate(
          'too_small_exclusive',
          params: {'min': exclusiveMin, 'actual': value},
        ),
        receivedValue: value,
        meta: {'min': exclusiveMin, 'actual': value},
      );
      (issues ??= []).add(applyCustomMessage(issue));
    }

    if (exclusiveMax != null && value >= exclusiveMax!) {
      final issue = ZemaIssue(
        code: 'too_big_exclusive',
        message: ZemaI18n.translate(
          'too_big_exclusive',
          params: {'max': exclusiveMax, 'actual': value},
        ),
        receivedValue: value,
        meta: {'max': exclusiveMax, 'actual': value},
      );
      (issues ??= []).add(applyCustomMessage(issue));
    }

    if (issues != null) return failure(issues);
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
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
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
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
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
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
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
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: true,
      );

  /// Requires the value to be strictly greater than [value] (`value > n`).
  ///
  /// Produces a `too_small_exclusive` issue on failure.
  ///
  /// ```dart
  /// z.double().gt(0.0)          // strictly positive
  /// z.double().gt(0.0).lt(1.0)  // open interval (0.0, 1.0)
  /// ```
  ZemaDouble gt(double value, {String? message}) => ZemaDouble(
        min: min,
        max: max,
        exclusiveMin: value,
        exclusiveMax: exclusiveMax,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: isFinite,
        customMessage: message,
      );

  /// Requires the value to be strictly less than [value] (`value < n`).
  ///
  /// Produces a `too_big_exclusive` issue on failure.
  ///
  /// ```dart
  /// z.double().lt(1.0)          // strictly less than 1
  /// z.double().gt(0.0).lt(1.0)  // open interval (0.0, 1.0)
  /// ```
  ZemaDouble lt(double value, {String? message}) => ZemaDouble(
        min: min,
        max: max,
        exclusiveMin: exclusiveMin,
        exclusiveMax: value,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: isFinite,
        customMessage: message,
      );

  /// Requires the value to be strictly less than zero (`value < 0.0`).
  ///
  /// Produces a `not_negative` issue on failure. Note that `0.0` is **not**
  /// negative — use [lte]`(0.0)` or [lt]`(0.0)` to include zero.
  ///
  /// ```dart
  /// z.double().negative()
  /// z.double().negative(message: 'Must be a loss value.')
  /// ```
  ZemaDouble negative({String? message}) => ZemaDouble(
        min: min,
        max: max,
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
        isPositive: isPositive,
        isNegative: true,
        isFinite: isFinite,
        customMessage: message,
      );

  /// Requires the value to be greater than or equal to zero (`value >= 0.0`).
  ///
  /// Produces a `too_small` issue on failure. Equivalent to [gte]`(0.0)`.
  ///
  /// ```dart
  /// z.double().nonNegative()
  /// z.double().nonNegative(message: 'Price cannot be negative.')
  /// ```
  ZemaDouble nonNegative({String? message}) => ZemaDouble(
        min: 0.0,
        max: max,
        exclusiveMin: exclusiveMin,
        exclusiveMax: exclusiveMax,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: isFinite,
        customMessage: message,
      );
}
