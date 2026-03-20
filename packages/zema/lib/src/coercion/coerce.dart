import 'package:zema/src/coercion/bool_coercion.dart';
import 'package:zema/src/coercion/double_coercion.dart';
import 'package:zema/src/coercion/int_coercion.dart';
import 'package:zema/src/coercion/string_coercion.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/primitives/datetime.dart';

/// Sub-namespace for coercing values to a target type before validating them.
///
/// Coercion schemas differ from strict schemas in one key way: instead of
/// rejecting an incompatible input immediately, they **attempt to convert** it
/// to the target type first. This is useful when your data arrives from
/// sources that don't preserve types — HTML form fields, URL query parameters,
/// environment variables, CSV files — where every value is technically
/// a string.
///
/// Access via `z.coerce()` — do not construct directly:
///
/// ```dart
/// z.coerce().integer()   // '42'  → 42
/// z.coerce().float()     // '3.14'→ 3.14
/// z.coerce().boolean()   // 'yes' → true
/// z.coerce().string()    // 42    → '42'
/// ```
///
/// ## Coercion vs strict schemas
///
/// | Input | `z.int()` | `z.coerce().integer()` |
/// |---|---|---|
/// | `42` | ✓ | ✓ |
/// | `42.0` | ✗ invalid_type | ✓ (whole number) |
/// | `'42'` | ✗ invalid_type | ✓ |
/// | `'42.5'` | ✗ invalid_type | ✗ invalid_coercion |
///
/// ## Combining with other schema methods
///
/// Coercion schemas extend [ZemaSchema], so every modifier and transformer
/// is available:
///
/// ```dart
/// z.coerce().integer(min: 1)          // coerce then range-check
/// z.coerce().integer().optional()     // null passes through
/// z.coerce().boolean().withDefault(false)
/// ```
///
/// See also:
/// - [ZemaSchema.preprocess] — for custom input transformations that are not
///   covered by the built-in coercions.
class ZemaCoerce {
  const ZemaCoerce();

  /// Creates a [CoerceInt] schema that coerces the input to an `int`.
  ///
  /// See [CoerceInt] for accepted input types and coercion rules.
  ///
  /// Set `strict: true` to disable string parsing (accept only `int` and
  /// whole-number `double`):
  ///
  /// ```dart
  /// z.coerce().integer()                       // int, double, string
  /// z.coerce().integer(strict: true)           // int and double only
  /// z.coerce().integer(min: 1)                 // coerce then assert >= 1
  /// z.coerce().integer(max: 255)               // coerce then assert <= 255
  /// z.coerce().integer(min: 0, max: 100)
  /// ```
  ///
  /// Failures produce `invalid_coercion`, `too_small`, or `too_big` issues.
  ZemaSchema<dynamic, int> integer({int? min, int? max, bool strict = false}) =>
      CoerceInt(min: min, max: max, strict: strict);

  /// Creates a [CoerceBool] schema that coerces the input to a `bool`.
  ///
  /// See [CoerceBool] for the full table of accepted truthy/falsy strings
  /// and integers. Set `strict: true` to accept only native `bool` values:
  ///
  /// ```dart
  /// z.coerce().boolean()               // bool, int (0/1), string
  /// z.coerce().boolean(strict: true)   // bool only
  /// ```
  ///
  /// Failure produces an `invalid_coercion` issue.
  ZemaSchema<dynamic, bool> boolean({bool strict = false}) =>
      CoerceBool(strict: strict);

  /// Creates a [CoerceDouble] schema that coerces the input to a `double`.
  ///
  /// See [CoerceDouble] for accepted input types and coercion rules.
  ///
  /// Set `strict: true` to disable string parsing (accept only `double` and
  /// `int`):
  ///
  /// ```dart
  /// z.coerce().float()                        // double, int, string
  /// z.coerce().float(strict: true)            // double and int only
  /// z.coerce().float(min: 0.0)                // coerce then assert >= 0.0
  /// z.coerce().float(max: 1.0)                // coerce then assert <= 1.0
  /// ```
  ///
  /// Failures produce `invalid_coercion`, `too_small`, or `too_big` issues.
  ZemaSchema<dynamic, double> float({
    double? min,
    double? max,
    bool strict = false,
  }) =>
      CoerceDouble(min: min, max: max, strict: strict);

  /// Creates a [ZemaDateTime] schema that coerces the input to a [DateTime].
  ///
  /// Accepts three input representations:
  ///
  /// | Input | Parsing rule |
  /// |---|---|
  /// | `DateTime` | passed through unchanged |
  /// | `String` | parsed with [DateTime.tryParse] (ISO 8601) |
  /// | `int` | treated as milliseconds since the Unix epoch |
  /// | anything else | `invalid_coercion` failure |
  ///
  /// The optional [after] and [before] bounds are applied **after** coercion:
  ///
  /// ```dart
  /// z.coerce().dateTime()                            // any parseable date
  /// z.coerce().dateTime(after: DateTime(2000))       // on or after 2000-01-01
  /// z.coerce().dateTime(before: DateTime.now())      // must be in the past
  /// ```
  ///
  /// Failures produce `invalid_coercion`, `date_too_early`, or
  /// `date_too_late` issues.
  ZemaDateTime dateTime({DateTime? after, DateTime? before}) =>
      ZemaDateTime(min: after, max: before);

  /// Creates a [CoerceString] schema that coerces the input to a `String`.
  ///
  /// In the default **strict mode**, only known primitive types are accepted:
  /// `String`, `int`, `double`, `num`, `bool`, and `DateTime`. Arbitrary
  /// objects whose `.toString()` would produce `Instance of 'Foo'` are
  /// rejected with `invalid_coercion`.
  ///
  /// Set `strict: false` to revert to the permissive behaviour (any non-null
  /// value coerced via `.toString()`):
  ///
  /// ```dart
  /// z.coerce().string()               // strict — primitives only
  /// z.coerce().string(strict: false)  // permissive — any object
  /// ```
  ZemaSchema<dynamic, String> string({bool strict = true}) =>
      CoerceString(strict: strict);
}
