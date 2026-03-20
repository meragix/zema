import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zema/zema.dart';

/// Adds Zema schema validation directly on [http.Response].
///
/// The response body is decoded from JSON before validation.
///
/// Example:
/// ```dart
/// import 'package:zema_http/zema_http.dart';
///
/// final schema = z.object({'id': z.integer(), 'name': z.string()});
///
/// final response = await client.get(Uri.parse('/users/1'));
///
/// // Returns T or throws ZemaException on validation failure.
/// final user = response.parse(schema);
///
/// // Returns ZemaResult<T>, never throws.
/// final result = response.safeParse(schema);
/// ```
extension ZemaHttpResponseX on http.Response {
  /// Decodes [body] as JSON and validates it against [schema].
  ///
  /// Returns the parsed output on success.
  /// Throws [ZemaException] if validation fails.
  /// Throws [FormatException] if [body] is not valid JSON.
  T parse<T>(ZemaSchema<dynamic, T> schema) =>
      schema.parse(jsonDecode(body));

  /// Decodes [body] as JSON and validates it against [schema].
  ///
  /// Returns [ZemaSuccess] on success or [ZemaFailure] on validation failure.
  /// Never throws. Wraps [FormatException] as a [ZemaFailure] with code
  /// `invalid_json`.
  ZemaResult<T> safeParse<T>(ZemaSchema<dynamic, T> schema) {
    try {
      return schema.safeParse(jsonDecode(body));
    } on FormatException catch (e) {
      return ZemaFailure([
        ZemaIssue(
          code: 'invalid_json',
          message: e.message,
          receivedValue: body,
        ),
      ]);
    }
  }
}
