import 'package:zema/src/coercion/bool_coercion.dart';
import 'package:zema/src/coercion/double_coercion.dart';
import 'package:zema/src/coercion/int_coercion.dart';
import 'package:zema/src/coercion/string_coercion.dart';
import 'package:zema/src/core/schema.dart';

/// Coercion namespace for type transformations
class ZemaCoerce {
  const ZemaCoerce();

  /// Coerce to integer from string or number
  ZemaSchema<dynamic, int> integer({int? min, int? max}) =>
      CoerceInt(min: min, max: max);

  /// Coerce to boolean from string or number
  ZemaSchema<dynamic, bool> boolean() => const CoerceBool();

  /// Coerce to double from string or number
  ZemaSchema<dynamic, double> float({double? min, double? max}) =>
      CoerceDouble(min: min, max: max);

  /// Coerce to string from any value
  ZemaSchema<dynamic, String> string() => const CoerceString();
}
