import 'package:meta/meta.dart';
import 'package:zema/src/coercion/coerce.dart';
import 'package:zema/src/complex/array.dart';
import 'package:zema/src/complex/object.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/primitives/bool.dart';
import 'package:zema/src/primitives/number.dart';
import 'package:zema/src/primitives/string.dart';

/// Global factory for creating Zema schemas
@immutable
class Zema {
  const Zema._();

  static const Zema instance = Zema._();

  // Primitives schema
  ZemaString string() => const ZemaString();
  ZemaInt int() => const ZemaInt();
  ZemaDouble double() => const ZemaDouble();
  ZemaBool boolean() => const ZemaBool();

  // Complex types
  ZemaArray<T> array<T>(ZemaSchema<dynamic, T> element) => ZemaArray(element);
  ZemaObject<Map<String, dynamic>> object(
    Map<String, ZemaSchema<dynamic, dynamic>> shape,
  ) =>
      ZemaObject(shape);

  /// Create typed object schema with constructor
  ZemaObject<T> objectAs<T extends Object>(
    Map<String, ZemaSchema<dynamic, dynamic>> shape,
    T Function(Map<String, dynamic>) constructor,
  ) =>
      ZemaObject(shape, constructor: constructor);

  // Coercion
  ZemaCoerce coerce() => const ZemaCoerce();
}

/// The entry point for Zema schema definitions.
///
/// Use [z] to create schemas in a concise, readable way.
///
/// ```dart
/// final schema = z.object({
///   'name': z.string().min(2),
///   'age': z.int().positive(),
///   'email': z.string().email(),
/// });
/// ```
const z = Zema.instance;

/// Alias for [z] for developers who prefer a more explicit naming convention.
const zema = z;
