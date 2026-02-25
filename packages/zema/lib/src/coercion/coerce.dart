import 'package:zema/src/coercion/bool_coercion.dart';
import 'package:zema/src/coercion/double_coercion.dart';
import 'package:zema/src/coercion/int_coercion.dart';
import 'package:zema/src/coercion/string_coercion.dart';
import 'package:zema/src/core/schema.dart';

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
  /// The optional [min] and [max] bounds are applied **after** coercion:
  ///
  /// ```dart
  /// z.coerce().integer()            // any coercible integer
  /// z.coerce().integer(min: 1)      // coerce then assert >= 1
  /// z.coerce().integer(max: 255)    // coerce then assert <= 255
  /// z.coerce().integer(min: 0, max: 100)
  /// ```
  ///
  /// Failures produce `invalid_coercion`, `too_small`, or `too_big` issues.
  ZemaSchema<dynamic, int> integer({int? min, int? max}) =>
      CoerceInt(min: min, max: max);

  /// Creates a [CoerceBool] schema that coerces the input to a `bool`.
  ///
  /// See [CoerceBool] for the full table of accepted truthy/falsy strings
  /// and integers.
  ///
  /// ```dart
  /// z.coerce().boolean()
  /// ```
  ///
  /// Failure produces an `invalid_coercion` issue.
  ZemaSchema<dynamic, bool> boolean() => const CoerceBool();

  /// Creates a [CoerceDouble] schema that coerces the input to a `double`.
  ///
  /// See [CoerceDouble] for accepted input types and coercion rules.
  ///
  /// The optional [min] and [max] bounds are applied **after** coercion:
  ///
  /// ```dart
  /// z.coerce().float()              // any coercible double
  /// z.coerce().float(min: 0.0)      // coerce then assert >= 0.0
  /// z.coerce().float(max: 1.0)      // coerce then assert <= 1.0
  /// ```
  ///
  /// Failures produce `invalid_coercion`, `too_small`, or `too_big` issues.
  ZemaSchema<dynamic, double> float({double? min, double? max}) =>
      CoerceDouble(min: min, max: max);

  /// Creates a [CoerceString] schema that coerces the input to a `String`.
  ///
  /// See [CoerceString] for coercion behaviour (effectively calls
  /// `.toString()` on any non-null value).
  ///
  /// ```dart
  /// z.coerce().string()
  /// ```
  ZemaSchema<dynamic, String> string() => const CoerceString();
}
