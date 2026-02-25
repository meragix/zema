import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A coercion schema that converts loosely-typed input to a Dart `double`.
///
/// Construct via `z.coerce().float()` — do not instantiate directly.
///
/// ## Coercion rules
///
/// | Input | Output |
/// |---|---|
/// | `double` | passed through unchanged |
/// | `int` | widened to `double` via `.toDouble()` |
/// | `String` parseable by `double.parse` | parsed double |
/// | `String` not parseable (e.g. `'abc'`) | `invalid_coercion` failure |
/// | anything else | `invalid_coercion` failure |
///
/// String input is **whitespace-trimmed** before parsing, so `' 3.14 '`
/// is treated the same as `'3.14'`. Scientific notation (`'1e3'`) and
/// special values (`'Infinity'`, `'NaN'`) are accepted by `double.parse`
/// and will be passed through.
///
/// ## Range constraints
///
/// The optional [min] and [max] bounds are enforced **after** coercion
/// succeeds. Both can be set independently:
///
/// ```dart
/// z.coerce().float()                 // any coercible double
/// z.coerce().float(min: 0.0)         // >= 0.0 after coercion
/// z.coerce().float(max: 1.0)         // <= 1.0 after coercion
/// z.coerce().float(min: 0.0, max: 1.0)
/// ```
///
/// ## Examples
///
/// ```dart
/// final schema = z.coerce().float();
///
/// schema.parse(3.14);     // 3.14
/// schema.parse(42);       // 42.0   (int widened)
/// schema.parse('3.14');   // 3.14
/// schema.parse(' 1e3 ');  // 1000.0 (trimmed, scientific notation)
///
/// schema.parse('abc');    // fails — invalid_coercion
/// schema.parse(true);     // fails — invalid_coercion
/// ```
///
/// Range failures produce `too_small` or `too_big` issues respectively.
///
/// See also:
/// - [ZemaCoerce.float] — factory method on the `z.coerce()` namespace.
/// - `z.double()` — strict schema that only accepts actual `double` values.
final class CoerceDouble extends ZemaSchema<dynamic, double> {
  /// Lower bound (inclusive). Applied after coercion. `null` means no limit.
  final double? min;

  /// Upper bound (inclusive). Applied after coercion. `null` means no limit.
  final double? max;

  const CoerceDouble({this.min, this.max});

  @override
  ZemaResult<double> safeParse(dynamic value) {
    double? parsed;

    if (value is double) {
      parsed = value;
    } else if (value is int) {
      parsed = value.toDouble();
    } else if (value is String) {
      parsed = double.tryParse(value.trim());
    }

    if (parsed == null) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_coercion',
          message: ZemaI18n.translate(
            'invalid_coercion',
            params: {'type': 'double'},
          ),
          meta: {'actual': value.runtimeType},
        ),
      );
    }

    final issues = <ZemaIssue>[];

    if (min != null && parsed < min!) {
      issues.add(
        ZemaIssue(
          code: 'too_small',
          message: ZemaI18n.translate(
            'too_small',
            params: {
              'min': min,
              'actual': parsed,
            },
          ),
          meta: {'min': min, 'actual': parsed},
        ),
      );
    }

    if (max != null && parsed > max!) {
      issues.add(
        ZemaIssue(
          code: 'too_big',
          message: ZemaI18n.translate(
            'too_big',
            params: {
              'max': max,
              'actual': parsed,
            },
          ),
          meta: {'max': max, 'actual': parsed},
        ),
      );
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(parsed);
  }
}
