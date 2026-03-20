/// Zema schema validation extension for Dio HTTP responses.
///
/// ```dart
/// import 'package:zema_dio/zema_dio.dart';
///
/// final schema = z.object({'id': z.integer(), 'name': z.string()});
/// final response = await dio.get('/users/1');
///
/// // Throws ZemaException on validation failure.
/// final user = response.parse(schema);
///
/// // Returns ZemaResult<T>, never throws.
/// final result = response.safeParse(schema);
/// ```
library;

export 'src/dio_response_extension.dart';
