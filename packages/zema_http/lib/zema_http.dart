/// Zema schema validation extension for package:http responses.
///
/// ```dart
/// import 'package:zema_http/zema_http.dart';
///
/// final schema = z.object({'id': z.integer(), 'name': z.string()});
/// final response = await client.get(Uri.parse('/users/1'));
///
/// // Throws ZemaException on validation failure.
/// final user = response.parse(schema);
///
/// // Returns ZemaResult<T>, never throws.
/// final result = response.safeParse(schema);
/// ```
library;

export 'src/http_response_extension.dart';
