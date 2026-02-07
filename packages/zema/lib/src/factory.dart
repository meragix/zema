import 'package:meta/meta.dart';
import 'package:zema/src/coercion/coercion.dart';
import 'package:zema/src/primitives/bool_shema.dart';
import 'package:zema/src/primitives/number_schema.dart';
import 'package:zema/src/primitives/string_schema.dart';

/// Global factory for creating Zema schemas
///
/// Example:
/// ```dart
/// final schema = Z.object({
///   'name': Z.string.min(2),
///   'age': Z.int.positive(),
///   'email': Z.string.email(),
/// });
///
@immutable
class Zema {
  const Zema._();

  // Primitives schema
  static const ZemaString string = ZemaString();
  static const ZemaInt int = ZemaInt();
  static const ZemaDouble number = ZemaDouble();
  static const ZemaBool boolean = ZemaBool();

  // Complex types

  // Coercion
  static const ZemaCoerce coerce = ZemaCoerce();
}
