import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A coercion schema that converts loosely-typed input to a Dart `bool`.
///
/// Construct via `z.coerce().boolean()` — do not instantiate directly.
///
/// ## Coercion rules
///
/// | Input | Output |
/// |---|---|
/// | `bool` | passed through unchanged |
/// | `int` `1` | `true` |
/// | `int` `0` | `false` |
/// | `String` `'true'` `'1'` `'yes'` `'on'` | `true` |
/// | `String` `'false'` `'0'` `'no'` `'off'` | `false` |
/// | anything else | `invalid_coercion` failure |
///
/// String matching is **case-insensitive** and **whitespace-trimmed**, so
/// `'  True '`, `'TRUE'`, and `'true'` are all equivalent.
///
/// ```dart
/// final schema = z.coerce().boolean();
///
/// schema.parse(true);    // true
/// schema.parse(1);       // true
/// schema.parse('yes');   // true
/// schema.parse('ON');    // true
///
/// schema.parse(false);   // false
/// schema.parse(0);       // false
/// schema.parse('no');    // false
/// schema.parse('off');   // false
///
/// schema.parse('maybe'); // fails — invalid_coercion
/// schema.parse(2);       // fails — invalid_coercion
/// ```
///
/// See also:
/// - [ZemaCoerce.boolean] — factory method on the `z.coerce()` namespace.
/// - `z.boolean()` — strict schema that only accepts actual `bool` values.
final class CoerceBool extends ZemaSchema<dynamic, bool> {
  const CoerceBool();

  @override
  ZemaResult<bool> safeParse(dynamic value) {
    if (value is bool) return success(value);

    if (value is int) {
      if (value == 1) return success(true);
      if (value == 0) return success(false);
    }

    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on') {
        return success(true);
      }
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'off') {
        return success(false);
      }
    }

    return singleFailure(
      ZemaIssue(
        code: 'invalid_coercion',
        message: ZemaI18n.translate(
          'invalid_coercion',
          params: {'type': 'bool'},
        ),
        meta: {'actual': value.runtimeType},
      ),
    );
  }
}
