import 'package:meta/meta.dart';
import 'package:zema/src/coercion/coerce.dart';
import 'package:zema/src/complex/array.dart';
import 'package:zema/src/complex/object.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/primitives/bool.dart';
import 'package:zema/src/primitives/number.dart';
import 'package:zema/src/primitives/string.dart';

/// Global factory for creating Zema schemas
///
/// Example:
/// ```dart
/// final schema = z.object({
///   'name': z.string.min(2),
///   'age': z.int.positive(),
///   'email': z.string.email(),
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
  static ZemaArray<T> array<T>(ZemaSchema<dynamic, T> element) =>
      ZemaArray(element);
  static ZemaObject<Map<String, dynamic>> object(
    Map<String, ZemaSchema<dynamic, dynamic>> shape,
  ) =>
      ZemaObject(shape);

  // static ZemaObject<T> objectAs<T extends Object>(
  //   Map<String, ZemaSchema<dynamic, dynamic>> shape,
  //   T Function(Map<String, dynamic>) constructor,
  // ) =>
  //     ZemaObject(shape, constructor: constructor);

  // Coercion
  static const ZemaCoerce coerce = ZemaCoerce();
}

/// Alias for [Zema] to create schemas with a concise syntax
const z = Zema._();
