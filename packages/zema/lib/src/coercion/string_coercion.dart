import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A coercion schema that converts primitive values to a `String`.
///
/// Construct via `z.coerce().string()` — do not instantiate directly.
///
/// ## Strict mode (default)
///
/// By default [strict] is `true` and only known primitive types are accepted:
/// `String`, `int`, `double`, `num`, `bool`, and `DateTime`. Any other type
/// produces an `invalid_coercion` failure — preventing useless strings like
/// `"Instance of 'User'"`.
///
/// `DateTime` values are converted to their ISO 8601 string representation
/// via `.toIso8601String()` rather than the default `.toString()`.
///
/// | Input | Output (strict) |
/// |---|---|
/// | `String` | passed through unchanged |
/// | `int` `42` | `'42'` |
/// | `double` `3.14` | `'3.14'` |
/// | `bool` `true` | `'true'` |
/// | `num` | `.toString()` |
/// | `DateTime` | `.toIso8601String()` |
/// | any other type | `invalid_coercion` |
///
/// ## Permissive mode
///
/// Set `strict: false` to coerce **any** non-null value via `.toString()`.
/// Use this when you are certain that all input types have a meaningful
/// string representation.
///
/// ```dart
/// z.coerce().string()               // strict — primitives only
/// z.coerce().string(strict: false)  // permissive — any object
/// ```
///
/// ## Examples
///
/// ```dart
/// final schema = z.coerce().string();
///
/// schema.parse('hello');           // 'hello'
/// schema.parse(42);                // '42'
/// schema.parse(3.14);              // '3.14'
/// schema.parse(true);              // 'true'
/// schema.parse(DateTime(2024, 1)); // '2024-01-01T00:00:00.000'
///
/// schema.parse(Object());          // fails — invalid_coercion (strict mode)
/// ```
///
/// See also:
/// - [ZemaCoerce.string] — factory method on the `z.coerce()` namespace.
/// - `z.string()` — strict schema that only accepts actual `String` values.
final class CoerceString extends ZemaSchema<dynamic, String> {
  /// When `true` (default), only known primitive types are accepted.
  /// When `false`, any non-null value is coerced via `.toString()`.
  final bool strict;

  const CoerceString({this.strict = true});

  static const _allowedTypes = {
    String,
    int,
    double,
    num,
    bool,
    DateTime,
  };

  @override
  ZemaResult<String> safeParse(dynamic value) {
    if (strict && !_allowedTypes.contains(value.runtimeType)) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_coercion',
          message: ZemaI18n.translate(
            'invalid_coercion',
            params: {'type': 'String'},
          ),
          meta: {'actual': value.runtimeType.toString(), 'type': 'String'},
        ),
      );
    }

    try {
      final result =
          value is DateTime ? value.toIso8601String() : value.toString();
      return success(result);
    } catch (e) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_coercion',
          message: ZemaI18n.translate(
            'invalid_coercion',
            params: {'type': 'String'},
          ),
          meta: {'actual': value.runtimeType.toString()},
        ),
      );
    }
  }
}
