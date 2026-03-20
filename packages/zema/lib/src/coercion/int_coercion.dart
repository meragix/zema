import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A coercion schema that converts loosely-typed input to a Dart `int`.
///
/// Construct via `z.coerce().integer()` — do not instantiate directly.
///
/// ## Standard mode (default)
///
/// Accepts `int`, whole-number `double`, and parseable `String`.
///
/// | Input | Output |
/// |---|---|
/// | `int` | passed through unchanged |
/// | `double` with no fractional part (`42.0`) | truncated to `int` (`42`) |
/// | `double` with a fractional part (`42.5`) | `invalid_coercion` failure |
/// | `String` parseable by `int.parse` | parsed integer |
/// | `String` not parseable (e.g. `'3.14'`, `'abc'`) | `invalid_coercion` failure |
/// | anything else | `invalid_coercion` failure |
///
/// String input is **whitespace-trimmed** before parsing.
///
/// ## Strict mode
///
/// Set `strict: true` to accept only `int` and whole-number `double`.
/// String parsing is disabled. Use this when string coercion is undesirable
/// (e.g. internal pipeline data where strings should never appear).
///
/// ```dart
/// z.coerce().integer()               // standard — int, double, string
/// z.coerce().integer(strict: true)   // strict — int and double only
/// ```
///
/// ## Range constraints
///
/// Applied **after** coercion succeeds:
///
/// ```dart
/// z.coerce().integer(min: 0)         // >= 0 after coercion
/// z.coerce().integer(max: 100)       // <= 100 after coercion
/// z.coerce().integer(strict: true, min: 1, max: 10)
/// ```
///
/// Range failures produce `too_small` or `too_big` issues respectively.
///
/// See also:
/// - [ZemaCoerce.integer] — factory method on the `z.coerce()` namespace.
/// - `z.int()` — strict schema that only accepts actual `int` values.
final class CoerceInt extends ZemaSchema<dynamic, int> {
  /// Lower bound (inclusive). Applied after coercion. `null` means no limit.
  final int? min;

  /// Upper bound (inclusive). Applied after coercion. `null` means no limit.
  final int? max;

  /// When `true`, string parsing is disabled; only `int` and whole-number
  /// `double` are accepted. Default `false`.
  final bool strict;

  const CoerceInt({this.min, this.max, this.strict = false});

  @override
  ZemaResult<int> safeParse(dynamic value) {
    int? parsed;

    if (value is int) {
      parsed = value;
    } else if (value is double) {
      if (value == value.truncateToDouble()) {
        parsed = value.toInt();
      }
    } else if (!strict && value is String) {
      parsed = int.tryParse(value.trim());
    }

    if (parsed == null) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_coercion',
          message: ZemaI18n.translate(
            'invalid_coercion',
            params: {'type': 'int'},
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
