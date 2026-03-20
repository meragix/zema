# zema_http

[![pub.dev](https://img.shields.io/pub/v/zema_http.svg)](https://pub.dev/packages/zema_http)

Zema schema validation extension for [package:http](https://pub.dev/packages/http) responses.

Adds `.parse()` and `.safeParse()` directly on `http.Response`. The body is decoded from JSON automatically before validation.

## Installation

```yaml
dependencies:
  zema: ^0.4.0
  zema_http: ^0.1.0
  http: ^1.2.0
```

## Usage

```dart
import 'package:http/http.dart' as http;
import 'package:zema/zema.dart';
import 'package:zema_http/zema_http.dart';

final userSchema = z.object({
  'id':    z.integer(),
  'name':  z.string().min(1),
  'email': z.string().email(),
});

final client = http.Client();

// --- parse(): returns T or throws ZemaException ---
try {
  final response = await client.get(Uri.parse('https://api.example.com/users/1'));
  final user = response.parse(userSchema);
  print(user['email']);
} on ZemaException catch (e) {
  print(e.issues); // List<ZemaIssue>
} on FormatException catch (e) {
  print('Response body is not valid JSON: $e');
}

// --- safeParse(): returns ZemaResult<T>, never throws ---
final response = await client.get(Uri.parse('https://api.example.com/users/1'));
final result = response.safeParse(userSchema);

switch (result) {
  case ZemaSuccess(:final value):
    print(value['email']);
  case ZemaFailure(:final errors):
    for (final issue in errors) {
      print('${issue.path}: ${issue.message}');
    }
}
```

## API

| Method      | Signature                                            | Behaviour                                                                                                |
|-------------|------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| `parse`     | `T parse<T>(ZemaSchema<dynamic, T>)`                 | Decodes JSON, returns `T` or throws `ZemaException`. Throws `FormatException` if body is not valid JSON. |
| `safeParse` | `ZemaResult<T> safeParse<T>(ZemaSchema<dynamic, T>)` | Decodes JSON, returns `ZemaSuccess` or `ZemaFailure`. Never throws. See note below.                      |

`safeParse` wraps `FormatException` as a `ZemaFailure` with issue code `invalid_json` and the raw body as `receivedValue`, so you can handle both HTTP and validation errors with a single `switch`.

## Error codes

| Code           | Cause                                                                             |
|----------------|-----------------------------------------------------------------------------------|
| `invalid_json` | Response body is not valid JSON                                                   |
| any Zema code  | Schema validation failure (see [core docs](https://meragix.github.io/zema/core)) |

## Related packages

- [`zema`](https://pub.dev/packages/zema) — core schema library
- [`zema_dio`](https://pub.dev/packages/zema_dio) — same extension for Dio
- [`zema_forms`](https://pub.dev/packages/zema_forms) — Flutter form integration
