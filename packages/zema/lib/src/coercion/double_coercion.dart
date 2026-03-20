import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A coercion schema that converts loosely-typed input to a Dart `double`.
///
/// Construct via `z.coerce().float()` — do not instantiate directly.
///
/// ## Standard mode (default)
///
/// Accepts `double`, `int`, and parseable `String`.
///
/// | Input | Output |
/// |---|---|
/// | `double` | passed through unchanged |
/// | `int` | widened to `double` via `.toDouble()` |
/// | `String` parseable by `double.parse` | parsed double |
/// | `String` not parseable (e.g. `'abc'`) | `invalid_coercion` failure |
/// | anything else | `invalid_coercion` failure |
///
/// String input is **whitespace-trimmed**. Scientific notation (`'1e3'`) and
/// special values (`'Infinity'`, `'NaN'`) are accepted by `double.parse`
/// and are passed through.
///
/// ## Strict mode
///
/// Set `strict: true` to accept only `double` and `int`. String parsing is
/// disabled. Use this when string coercion is undesirable.
///
/// ```dart
/// z.coerce().float()               // standard — double, int, string
/// z.coerce().float(strict: true)   // strict — double and int only
/// ```
///
/// ## Range constraints
///
/// Applied **after** coercion succeeds:
///
/// ```dart
/// z.coerce().float(min: 0.0)        // >= 0.0 after coercion
/// z.coerce().float(max: 1.0)        // <= 1.0 after coercion
/// z.coerce().float(strict: true, min: 0.0, max: 1.0)
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

  /// When `true`, string parsing is disabled; only `double` and `int` are
  /// accepted. Default `false`.
  final bool strict;

  const CoerceDouble({this.min, this.max, this.strict = false});

  @override
  ZemaResult<double> safeParse(dynamic value) {
    double? parsed;

    if (value is double) {
      parsed = value;
    } else if (value is int) {
      parsed = value.toDouble();
    } else if (!strict && value is String) {
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
          meta: {'actual': value.runtimeType.toString()},
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
            params: {'min': min, 'actual': parsed},
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
            params: {'max': max, 'actual': parsed},
          ),
          meta: {'max': max, 'actual': parsed},
        ),
      );
    }

    if (issues.isNotEmpty) return failure(issues);
    return success(parsed);
  }
}
