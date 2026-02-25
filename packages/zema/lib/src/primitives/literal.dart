import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A schema that accepts **only** a single exact value.
///
/// Construct via `z.literal(value)` — do not instantiate directly.
///
/// Equality is tested with `==`. Any input that does not equal the expected
/// [value] produces an `invalid_literal` issue.
///
/// ## Type parameter
///
/// [T] is inferred from the [value] you provide, giving you a fully typed
/// schema whose output is guaranteed to be that exact value:
///
/// ```dart
/// ZemaLiteral<String> = z.literal('admin')
/// ZemaLiteral<int>    = z.literal(42)
/// ZemaLiteral<bool>   = z.literal(true)
/// ```
///
/// ## Examples
///
/// ```dart
/// z.literal('admin').parse('admin');   // 'admin'
/// z.literal('admin').parse('user');    // fails — invalid_literal
///
/// z.literal(42).parse(42);             // 42
/// z.literal(42).parse(43);             // fails — invalid_literal
///
/// z.literal(true).parse(true);         // true
/// z.literal(true).parse(1);            // fails — int != bool
/// ```
///
/// ## Union of literals
///
/// Combine multiple [ZemaLiteral] schemas with [ZemaSchema.pipe] and
/// `z.union` to express a closed set of allowed values:
///
/// ```dart
/// final roleSchema = z.union([
///   z.literal('admin'),
///   z.literal('editor'),
///   z.literal('viewer'),
/// ]);
///
/// roleSchema.parse('admin');    // 'admin'
/// roleSchema.parse('unknown');  // fails
/// ```
///
/// For string enumerations you can also use `z.string().oneOf([...])`, which
/// produces a more descriptive `invalid_enum` issue with the allowed values
/// listed in `meta['allowed']`.
///
/// See also:
/// - `z.string().oneOf(values)` — for a closed string set with richer errors.
/// - `z.union(schemas)` — for combining multiple schemas into one.
final class ZemaLiteral<T> extends ZemaSchema<dynamic, T> {
  /// The exact value this schema accepts.
  final T value;

  const ZemaLiteral(this.value);

  @override
  ZemaResult<T> safeParse(dynamic input) {
    if (input == value) {
      return success(value);
    }

    return singleFailure(
      ZemaIssue(
        code: 'invalid_literal',
        message: ZemaI18n.translate('invalid_literal'),
      ),
    );
  }
}
