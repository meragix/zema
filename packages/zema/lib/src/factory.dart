import 'package:meta/meta.dart';
import 'package:zema/src/coercion/coerce.dart';
import 'package:zema/src/complex/complex.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/custom/custom_schema.dart';
import 'package:zema/src/effects/lazy.dart';
import 'package:zema/src/primitives/primitives.dart';

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

  // Create typed object schema with constructor
  ZemaObject<T> objectAs<T extends Object>(
    Map<String, ZemaSchema<dynamic, dynamic>> shape,
    T Function(Map<String, dynamic>) constructor,
  ) =>
      ZemaObject(shape, constructor: constructor);

  ZemaMap<K, V> map<K, V>(
    ZemaSchema<dynamic, K> keySchema,
    ZemaSchema<dynamic, V> valueSchema,
  ) =>
      ZemaMap(keySchema, valueSchema);

  // Coercion
  ZemaCoerce coerce() => const ZemaCoerce();

  // Create a union type (discriminated or not)
  ZemaUnion<T> union<T>(List<ZemaSchema<dynamic, T>> schemas) => ZemaUnion(schemas);

  // Lazy schema for recursive types
  ZemaSchema<I, O> lazy<I, O>(ZemaSchema<I, O> Function() fn) => LazySchema(fn);

  // Literal value schema
  ZemaLiteral<T> literal<T>(T value) => ZemaLiteral(value);

  // Custom validator
  ZemaSchema<T, T> custom<T>(
    bool Function(T) validator, {
    String? message,
  }) =>
      CustomSchema(validator, message);
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
