import 'package:dio/dio.dart';
import 'package:zema/zema.dart';

/// Adds Zema schema validation directly on [Response].
///
/// Example:
/// ```dart
/// import 'package:zema_dio/zema_dio.dart';
///
/// final schema = z.object({'id': z.integer(), 'name': z.string()});
///
/// final response = await dio.get('/users/1');
///
/// // Returns T or throws ZemaException on validation failure.
/// final user = response.parse(schema);
///
/// // Returns ZemaResult<T>, never throws.
/// final result = response.safeParse(schema);
/// ```
extension ZemaDioResponseX<E> on Response<E> {
  /// Validates [data] against [schema].
  ///
  /// Returns the parsed output on success.
  /// Throws [ZemaException] if validation fails.
  T parse<T>(ZemaSchema<dynamic, T> schema) => schema.parse(data);

  /// Validates [data] against [schema].
  ///
  /// Returns [ZemaSuccess] on success or [ZemaFailure] on validation failure.
  /// Never throws.
  ZemaResult<T> safeParse<T>(ZemaSchema<dynamic, T> schema) =>
      schema.safeParse(data);
}
