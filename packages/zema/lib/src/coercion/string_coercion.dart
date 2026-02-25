import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A coercion schema that converts any non-null value to a `String`.
///
/// Construct via `z.coerce().string()` — do not instantiate directly.
///
/// ## Coercion rules
///
/// Calls `.toString()` on the input value. This succeeds for virtually every
/// Dart object — the only way it can fail is if `.toString()` itself throws,
/// which is extremely rare and would indicate a broken object.
///
/// | Input | Output |
/// |---|---|
/// | `String` | passed through unchanged |
/// | `int` `42` | `'42'` |
/// | `double` `3.14` | `'3.14'` |
/// | `bool` `true` | `'true'` |
/// | any other object | `object.toString()` |
/// | throws inside `.toString()` | `invalid_coercion` failure |
///
/// ## Examples
///
/// ```dart
/// final schema = z.coerce().string();
///
/// schema.parse('hello');  // 'hello'
/// schema.parse(42);       // '42'
/// schema.parse(3.14);     // '3.14'
/// schema.parse(true);     // 'true'
/// schema.parse(null);     // 'null'
/// ```
///
/// If you need to validate or transform the resulting string further,
/// chain additional schema methods after coercion:
///
/// ```dart
/// z.coerce().string().trim().min(1)   // coerce, trim, then check length
/// z.coerce().string().email()         // coerce then validate as email
/// ```
///
/// See also:
/// - [ZemaCoerce.string] — factory method on the `z.coerce()` namespace.
/// - `z.string()` — strict schema that only accepts actual `String` values.
final class CoerceString extends ZemaSchema<dynamic, String> {
  const CoerceString();

  @override
  ZemaResult<String> safeParse(dynamic value) {
    try {
      return success(value.toString());
    } catch (e) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_coercion',
          message: ZemaI18n.translate(
            'invalid_coercion',
            params: {'type': 'string'},
          ),
          meta: {'actual': value.runtimeType},
        ),
      );
    }
  }
}
